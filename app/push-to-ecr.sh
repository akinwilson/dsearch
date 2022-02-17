#! /bin/bash
set -e 

SERVICE=$1
ENV=$2
COMPONENT=$3
REPO="${SERVICE}-${COMPONENT}-${ENV}"

IMAGE=""
ACCOUNT="437996125465"
REGION="eu-west-2"

if [$COMPONENT == "indexer"]; then
    IMAGE="dockerfile.lambdaIndexer"
else
    IMAGE="dockerfile.searchEngine"
fi
# ...terraform commands    
docker build -f ${IMAGE} -t ${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/${REPO} .
aws ecr get-login-password \
    --region ${REGION} \
| docker login \
    --username AWS \
    --password-stdin ${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com

docker push ${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/${REPO}