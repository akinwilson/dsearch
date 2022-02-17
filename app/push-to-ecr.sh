#! /bin/bash
set -e 

SERVICE=$1
ENV=$2
COMPONENT=$3
IMAGE=$4

REPO="${SERVICE}-${COMPONENT}-${ENV}"
ACCOUNT="437996125465"
REGION="eu-west-2"

docker build -f ../app/${IMAGE} -t ${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/${REPO} .
aws ecr get-login-password \
    --region ${REGION} \
| docker login \
    --username AWS \
    --password-stdin ${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com

docker push ${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/${REPO}