#!/bin/bash

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
  echo "Error: $validation_errors" ; exit 1
fi

echo "initialize terraform..."
terraform init > /dev/null

# confirm bucket exists
echo "confirm bucket '$bucket_name' exists..."
all_buckets=$(aws s3 ls)
bucket_exists=0
for entry in $all_buckets; do
  entry=`echo $entry | sed 's/ *$//g'`
  if [ $entry == $bucket_name ]; then
    bucket_exists=1 ; break
  fi
done
if [[ $bucket_exists -eq 0 ]]; then
  echo "Error: Could not find bucket '$bucket_name'" ; exit 1
fi

# confirm terraform resource not already managed by state
echo "confirm terraform resource 'aws_s3_bucket.$terraform_name' not already managed by state..."
managed_resources=$(terraform state list | grep "aws_s3_bucket\.")
for resource in $managed_resources; do
  if [[ $resource == "aws_s3_bucket.$terraform_name" ]]; then
    echo "Error: Terraform resource '$terraform_name' is already managed by state." ; exit 1
  fi
done

# confirm bucket not already managed by state under a different resource name
echo "confirm bucket '$bucket_name' not already managed by state under a different resource name..."
for resource in $managed_resources; do
  resource_config=$(terraform state show ${resource} | grep "bucket.* = \"$bucket_name\"")
  if [[ -n $resource_config ]]; then 
    echo "Error: Bucket '$bucket_name' is already a managed resource under the name '$resource'" ; exit 1
  fi
done

# confirm no other terraform resource defined with same name
echo "confirm no other terraform resource defined with name 'aws_s3_bucket.$terraform_name'..."
for filename in *.tf; do
  [ -e "$filename" ] || continue
  resource_config=$(grep "[[:space:]]*resource[[:space:]]*\"aws_s3_bucket\"[[:space:]]*\"$terraform_name\"" $filename)
  if [[ -n $resource_config ]]; then
    echo "Error: Terraform resource named '$terraform_name' is already definedin '$filename'." ; exit 1
  fi
done

# create file with seed configuration
config_file="$terraform_name.tf"
echo "create file '$config_file' with seed configuration..."
if [ -f "$config_file" ]; then
    echo "Error: Please rename the file '$config_file' and rerun the command again." ; exit 1
fi
echo "resource \"aws_s3_bucket\" \"$terraform_name\" {}" > $config_file

# import terraform resource
echo "import bucket '$bucket_name' as terraform resource '$terraform_name'..."
terraform import aws_s3_bucket.$terraform_name $bucket_name > /dev/null

# flesh out configuration
echo "flesh out configuration in '$config_file'..."
terraform state show -no-color aws_s3_bucket.$terraform_name > $config_file

echo "Success: Configuration generated and resource imported!"
