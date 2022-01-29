set -e
aws s3 rb s3://infra-euw2 --force
exit 1