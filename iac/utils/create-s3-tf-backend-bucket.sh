set -e

# first need the bucket to exists in aws where the  state of the infrastructure is kept
aws s3api create-bucket \
--bucket infra-euw2 \
--acl private \
--region eu-west-2 \
--create-bucket-configuration '{"LocationConstraint": "eu-west-2"}' \
--profile akinwilson >/dev/null 

aws s3api put-bucket-tagging \
--bucket infra-euw2 \
--tagging 'TagSet=[{Key=purpose,Value=tf-store}]' \
--profile akinwilson >/dev/null

aws s3api put-bucket-versioning \
--bucket infra-euw2 \
--versioning-configuration Status=Enabled \
--profile akinwilson >/dev/null

exit 1