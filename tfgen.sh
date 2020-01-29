#!/bin/bash

# get arguments
bucket_name=$1
terraform_name=$2

# validate arguments
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

# get s3 buckets
all_buckets=$(aws s3 ls)

# validate bucket exists
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

echo "Found bucket '$bucket_name'"

# config no other terraform resource with same name
### config_exists=0
### for filename in currentDirectory; do
###   if [ $filename == *.tf ] && [ $filename.content contains $terraform_name ]; then
###     config_exists=1
###   fi
### done
### if [[ $config_exists -eq 1 ]]; then
###   echo "Error: Terraform resource named '$terraform_name' already exists." ; exit 1
### fi

# config bucket not already managed
### bucket_managed=0
### for filename in currentDirectory; do
###   if [ $filename == *.tf ] && [ $filename.content contains "bucket = $bucket_name" ]; then
###     bucket_managed=1
###   fi
### done
### if [[ $bucket_managed -eq 1 ]]; then
###   echo "Error: Bucket '$bucket_name' is already managed by your Terraform config." ; exit 1
### fi

# create a new .tf file for the s3 bucket
