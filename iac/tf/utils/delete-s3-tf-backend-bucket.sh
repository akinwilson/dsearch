set -e

# aws s3api delete-objects \
#     --bucket infra-euw2 \
#     --delete "$(aws s3api list-object-versions \
#     --bucket infra-euw2 \
#     --output=json \
#     --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')" > /dev/null
BUCKET=infra-euw2
# remove objects # remove buckets
# aws s3api delete-objects --bucket ${BUCKET} --delete "$(aws s3api list-object-versions --bucket ${BUCKET} --query='{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}')" > /dev/null
aws s3api delete-objects --bucket ${BUCKET} --delete "$(aws s3api list-object-versions --bucket ${BUCKET} --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')" > /dev/null
aws s3 rb s3://infra-euw2 --force
exit 1


