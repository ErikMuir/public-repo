#!/bin/bash

# get arguments
bucket_name=$1
terraform_name=$2

# validate arguments
validation_errors=""
[[ -n "$bucket_name" ]] || validation_errors+="Bucket name is required. "
[[ -n "$terraform_name" ]] || validation_errors+="Terraform name is required. "
if [[ -n "$validation_errors" ]]; then
  echo "$validation_errors" ; exit 1
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
  echo "Could not find bucket '$bucket_name'" ; exit 1
fi

echo "Found bucket '$bucket_name'"
