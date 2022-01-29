#!/usr/bin/env python
import boto3
s3 = boto3.resource('s3')
bucket = s3.Bucket('infra-euw2')
r = bucket.object_versions.all().delete()
print("Response:\n", r)
