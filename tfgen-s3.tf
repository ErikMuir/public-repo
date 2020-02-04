#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
NC="\e[0m"

# validate arguments
bucket_name=$1
terraform_name=$2
validation_errors=""
invalid_terraform_name_pattern='[^A-Za-z0-9_]'
[[ -n "$bucket_name" ]] || validation_errors+="Bucket name is required. "
[[ -n "$terraform_name" ]] || validation_errors+="Terraform name is required. "
if [[ $terraform_name =~ $invalid_terraform_name_pattern ]] || [[ $terraform_name == _* ]]; then
  validation_errors+="Terraform name is invalid. "
fi
if [[ -n "$validation_errors" ]]; then
  echo -e "$ERROR $validation_errors" ; exit 1
fi

echo "[1/8] initializing terraform..."
terraform init > /dev/null

echo "[2/8] confirming bucket exists..."
all_buckets=$(aws s3 ls)
bucket_exists=0
for entry in $all_buckets; do
  entry=`echo $entry | sed 's/ *$//g'`
  if [ $entry == $bucket_name ]; then
    bucket_exists=1 ; break
  fi
done
if [[ $bucket_exists -eq 0 ]]; then
  echo -e "${RED}Error: Could not find bucket '$bucket_name'.${NC}" ; exit 1
fi

echo "[3/8] confirming terraform resource is not already managed by state..."
managed_resources=$(terraform state list | grep "aws_s3_bucket\.")
for resource in $managed_resources; do
  if [[ $resource == "aws_s3_bucket.$terraform_name" ]]; then
    echo -e "${RED}Error: Terraform resource '$terraform_name' is already managed by state.${NC}" ; exit 1
  fi
done

echo "[4/8] confirming bucket is not already managed under a different resource name..."
for resource in $managed_resources; do
  resource_config=$(terraform state show ${resource} | grep "bucket.* = \"$bucket_name\"")
  if [[ -n $resource_config ]]; then 
    echo -e "${RED}Error: Bucket '$bucket_name' is already a managed resource under the name '$resource'.${NC}" ; exit 1
  fi
done

echo "[5/8] confirming no other terraform resource is managed under the same name..."
for filename in *.tf; do
  [ -e "$filename" ] || continue
  resource_config=$(grep "[[:space:]]*resource[[:space:]]*\"aws_s3_bucket\"[[:space:]]*\"$terraform_name\"" $filename)
  if [[ -n $resource_config ]]; then
    echo -e "${RED}Error: Terraform resource named '$terraform_name' is already defined in '$filename'.${NC}" ; exit 1
  fi
done

echo "[6/8] seeding configuration..."
config_file="aws_s3_bucket.$terraform_name.tf"
if [ -f "$config_file" ]; then
    echo -e "${RED}Error: There is already a file called '$config_file'.${NC}" ; exit 1
fi
echo "resource \"aws_s3_bucket\" \"$terraform_name\" {}" > $config_file

echo "[7/8] importing bucket as a managed terraform resource..."
terraform import aws_s3_bucket.$terraform_name $bucket_name > /dev/null

echo "[8/8] refreshing configuration..."
terraform state show -no-color aws_s3_bucket.$terraform_name > $config_file

echo -e "${GREEN}Configuration generated in '$config_file'. Import successful!${NC}"
