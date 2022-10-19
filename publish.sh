#!/bin/bash

set -euo pipefail

workspace=$1
dockerhub_repo=$2
ecr_repo=$3

if [ "$workspace" == "master" ]; then
    tag="latest"
elif [ "$workspace" == "prod" ]; then
    tag="v1"
else
    tag="$workspace"
fi


if [ "$workspace" == "master" ] || [ "$workspace" == "prod" ]; then
    echo "$DOCKERHUB_PASS" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin
    docker tag nginx-dynamic-acm "$dockerhub_repo:$tag"
    docker push "$dockerhub_repo:$tag"

    aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 659386482123.dkr.ecr.us-west-2.amazonaws.com
    docker tag nginx-dynamic-acm "$ecr_repo:$tag"
    docker push "$ecr_repo:$tag"
else
    aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 659386482123.dkr.ecr.us-west-2.amazonaws.com
    docker tag nginx-dynamic-acm "$ecr_repo:$tag"
    docker push "$ecr_repo:$tag"
fi
