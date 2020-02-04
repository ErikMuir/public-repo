#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
NC="\e[0m"

# validate arguments
table_name=$1
terraform_name=$2
validation_errors=""
invalid_terraform_name_pattern='[^A-Za-z0-9_]'
[[ -n "$table_name" ]] || validation_errors+="Table name is required. "
[[ -n "$terraform_name" ]] || validation_errors+="Terraform name is required. "
if [[ $terraform_name =~ $invalid_terraform_name_pattern ]] || [[ $terraform_name == _* ]]; then
  validation_errors+="Terraform name is invalid. "
fi
if [[ -n "$validation_errors" ]]; then
  echo -e "$ERROR $validation_errors" ; exit 1
fi

echo "[1/8] initializing terraform..."
terraform init > /dev/null

echo "[2/8] confirming table exists..."
all_tables=$(aws dynamodb list-tables)
table_exists=0
for entry in $all_tables; do
  entry=`echo $entry | sed 's/ *$//g'`
  if [[ $entry == *\"$table_name\"* ]]; then
    table_exists=1 ; break
  fi
done
if [[ $table_exists -eq 0 ]]; then
  echo -e "${RED}Error: Could not find table '$table_name'.${NC}" ; exit 1
fi

echo "[3/8] confirming terraform resource is not already managed by state..."
managed_resources=$(terraform state list | grep "aws_dynamodb_table\.")
for resource in $managed_resources; do
  if [[ $resource == "aws_dynamodb_table.$terraform_name" ]]; then
    echo -e "${RED}Error: Terraform resource '$terraform_name' is already managed by state.${NC}" ; exit 1
  fi
done

echo "[4/8] confirming table is not already managed under a different resource name..."
for resource in $managed_resources; do
  resource_config=$(terraform state show ${resource} | grep "name.* = \"$table_name\"")
  if [[ -n $resource_config ]]; then 
    echo -e "${RED}Error: Table '$table_name' is already a managed resource under the name '$resource'.${NC}" ; exit 1
  fi
done

echo "[5/8] confirming no other terraform resource is managed under the same name..."
for filename in *.tf; do
  [ -e "$filename" ] || continue
  resource_config=$(grep "[[:space:]]*resource[[:space:]]*\"aws_dynamodb_table\"[[:space:]]*\"$terraform_name\"" $filename)
  if [[ -n $resource_config ]]; then
    echo -e "${RED}Error: Terraform resource named '$terraform_name' is already defined in '$filename'.${NC}" ; exit 1
  fi
done

echo "[6/8] seeding configuration..."
config_file="aws_dynamodb_table.$terraform_name.tf"
if [ -f "$config_file" ]; then
    echo -e "${RED}Error: There is already a file called '$config_file'.${NC}" ; exit 1
fi
echo "resource \"aws_dynamodb_table\" \"$terraform_name\" {}" > $config_file

echo "[7/8] importing table as a managed terraform resource..."
terraform import aws_dynamodb_table.$terraform_name $table_name > /dev/null

echo "[8/8] refreshing configuration..."
terraform state show -no-color aws_dynamodb_table.$terraform_name > $config_file

echo -e "${GREEN}Configuration generated in '$config_file'. Import successful!${NC}"
