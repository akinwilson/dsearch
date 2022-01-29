set -e

# first need the bucket to exists in aws where the  state of the infrastructure is kept
aws s3api create-bucket \
--bucket search-infra-euw2 \
--acl private \
--region eu-west-2 \
--create-bucket-configuration '{"LocationConstraint": "eu-west-2"}' \
--profile akinwilson

aws s3api put-bucket-tagging \
--bucket search-infra-euw2 \
--tagging 'TagSet=[{Key=purpose,Value=mana-infra}]' \
--profile akinwilson

aws s3api put-bucket-versioning \
--bucket search-infra-euw2 \
--versioning-configuration Status=Enabled \
--profile akinwilson
