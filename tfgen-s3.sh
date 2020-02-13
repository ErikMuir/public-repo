#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
GREY="\e[1;30m"
NC="\e[0m"
step=0
invalid_terraform_name_pattern='[^A-Za-z0-9_]'
managed_buckets=""
policy=""
bucket_name=$1
terraform_name=$2
bucket_config_file="aws_s3_bucket.$terraform_name.tf"
policy_config_file="aws_s3_bucket_policy.$terraform_name.tf"

echoSuccess() {
  echo -e "${GREEN}$@${NC}"
}

echoWarning() {
  echo -e "${YELLOW}Warning: $@${NC}"
}

echoError() {
  echo -e "${RED}Error: $@${NC}"
}

echoStep() {
  ((step++)); echo -e "${GREY}[$step]${NC} $@..."
}

echoSection() {
  echo -e "${CYAN}--- $@ ---${NC}"
}

exitOnError() {
  if [ $? -gt 0 ]; then exit 1; fi
}

runStep() {
  echoStep $1
  $2 ${@:3}
  exitOnError
}

runSection() {
  echoSection $1
  $2 ${@:3}
}

validate() {
  local bucket_name=$1
  local terraform_resource=$2
  local validation_errors=""
  [[ -n "$bucket_name" ]] || validation_errors+="Bucket name is required. "
  [[ -n "$terraform_name" ]] || validation_errors+="Terraform name is required. "
  if [[ $terraform_name =~ $invalid_terraform_name_pattern ]] || [[ $terraform_name == _* ]]; then
    validation_errors+="Terraform name is invalid. "
  fi
  if [[ -n "$validation_errors" ]]; then
    echoError $validation_errors
    return 1
  fi
}

init() {
  terraform init > /dev/null; return $?
}

confirmAwsResource() {
  local all_buckets=$(aws s3 ls)
  local exists=0
  for entry in $all_buckets; do
    entry=`echo $entry | sed 's/ *$//g'`
    if [ $entry == $bucket_name ]; then
      exists=1; break
    fi
  done
  if [[ $exists -eq 0 ]]; then
    echoError "Could not find bucket $bucket_name."
    return 1
  fi 
}

getManagedBuckets() {
  managed_buckets=$(terraform state list | grep "aws_s3_bucket\."); return $?
}

confirmTerraformBucketNotInState() {
  for resource in $managed_buckets; do
    if [[ $resource == "aws_s3_bucket.$terraform_name" ]]; then
      echoError "Terraform resource $terraform_name is already managed by state."
      return 1
    fi
  done
}

confirmAwsBucketNotInState() {
  for resource in $managed_buckets; do
    local resource_config=$(terraform state show ${resource} | grep "bucket.* = \"$bucket_name\"")
    if [[ -n $resource_config ]]; then
      echoError "Bucket $bucket_name is already a managed resource under the name $resource."
      return 1
    fi
  done
}

confirmTerraformBucketNotInCode() {
  for file in *.tf; do
    [ -e "$file" ] || continue
    local resource_config=$(grep "[[:space:]]*resource[[:space:]]*\"aws_s3_bucket\"[[:space:]]*\"$terraform_name\"" $file)
    if [[ -n $resource_config ]]; then
      echoError "Terraform resource named $terraform_name is already defined in $file."
      return 1
    fi
  done
}

seedBucketConfig() {
  if [ -f "$bucket_config_file" ]; then
    echoError "There is already a file called $bucket_config_file."
    return 1
  fi
  echo "resource \"aws_s3_bucket\" \"$terraform_name\" {}" > $bucket_config_file
  return $?
}

importBucket() {
  terraform import aws_s3_bucket.$terraform_name $bucket_name > /dev/null
  return $?
}

refreshBucketConfig() {
  terraform state show -no-color aws_s3_bucket.$terraform_name > $bucket_config_file
  return $?
}

getPolicy() {
  policy=$(aws s3api get-bucket-policy --bucket $bucket_name --query Policy --output text 2>/dev/null)
  return 0
}

confirmTerraformPolicyNotInState() {
  local managed_policies=$(terraform state list | grep "aws_s3_bucket_policy\.")
  for resource in $managed_policies; do
    if [[ $resource == "aws_s3_bucket_policy.$terraform_name" ]]; then
      echoWarning "Bucket policy for $terraform_name is already managed by state."
      return -1
    fi
  done
}

confirmTerraformPolicyNotInCode() {
  for file in *.tf; do
    [ -e "$file" ] || continue
    local resource_config=$(grep "[[:space:]]*resource[[:space:]]*\"aws_s3_bucket_policy\"[[:space:]]*\"$terraform_name\"" $file)
    if [[ -n $resource_config ]]; then
      echoWarning "Bucket policy named $terraform_name is already defined in $file."
      return -1
    fi
  done
}

seedPolicyConfig() {
  if [ -f "$policy_config_file" ]; then
    echoError "There is already a file called $policy_config_file."
    return -1
  fi
  echo "resource \"aws_s3_bucket_policy\" \"$terraform_name\" {}" > $policy_config_file
  return $?
}

importPolicy() {
  terraform import aws_s3_bucket_policy.$terraform_name $bucket_name > /dev/null
  return $?
}

refreshPolicyConfig() {
  terraform state show -no-color aws_s3_bucket_policy.$terraform_name > $policy_config_file
  return $?
}

setupSection() {
  runStep "validating arguments" validate $bucket_name $terraform_name
  runStep "initializing terraform" init
}

importBucketSection() {
  runStep "confirming bucket exists" confirmAwsResource
  runStep "getting managed buckets from state" getManagedBuckets
  runStep "confirming terraform bucket is not already managed by state" confirmTerraformBucketNotInState
  runStep "confirming aws bucket is not already managed by state" confirmAwsBucketNotInState
  runStep "confirming terraform bucket is not already defined in code" confirmTerraformBucketNotInCode
  runStep "seeding bucket configuration" seedBucketConfig
  runStep "importing bucket as a managed terraform resource" importBucket
  runStep "refreshing bucket configuration" refreshBucketConfig
}

importPolicySection() {
  runStep "looking for bucket policy" getPolicy
  if [ -z "$policy" ]; then return 0; fi
  runStep "confirming terraform policy is not already managed by state" confirmTerraformPolicyNotInState
  if [[ $? -lt 0 ]]; then return 0; fi
  runStep "confirming terraform policy is not already defined in code" confirmTerraformPolicyNotInCode
  if [[ $? -lt 0 ]]; then return 0; fi
  runStep "seeding policy configuration" seedPolicyConfig
  if [[ $? -lt 0 ]]; then return 0; fi
  runStep "importing policy as a managed terraform resource" importPolicy
  if [[ $? -lt 0 ]]; then return 0; fi
  runStep "refreshing policy configuration" refreshPolicyConfig
  if [[ $? -lt 0 ]]; then return 0; fi
}

runSection "Getting Setup" setupSection
runSection "Importing Bucket" importBucketSection
runSection "Importing Policy" importPolicySection

echoSuccess "Successfully imported bucket $bucket_name with configuration as $terraform_name!"
