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
raw_buckets=$(aws s3 ls)
all_buckets=()
i=0
for segment in $raw_buckets; do
  ((i++))
  modulo=$(($i%3))
  if [[ $modulo -eq 0 ]]; then
    all_buckets+=("$segment")
  fi
done

# validate bucket name


echo "${all_buckets[*]}"
