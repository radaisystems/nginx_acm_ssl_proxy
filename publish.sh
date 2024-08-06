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


if [ "$workspace" == "master" ] || [ "$workspace" == "prod" ] || [ "$workspace" == "vishad/PLE-1877" ]; then
    echo "$DOCKERHUB_PASS" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin
    docker login artifacts.radai.com -u "$ARTIFACTORY_USERNAME" -p "$ARTIFACTORY_PASSWORD"
    docker tag nginx-dynamic-acm "$dockerhub_repo:$tag"
    docker tag nginx-dynamic-acm artifacts.radai.com/local-platform-container-release/nginx/radai_nginx_dynamic_acm:"$tag"
    docker push artifacts.radai.com/local-platform-container-release/nginx/radai_nginx_dynamic_acm:"$tag"
    docker push "$dockerhub_repo:$tag"

    aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 659386482123.dkr.ecr.us-west-2.amazonaws.com
    docker tag nginx-dynamic-acm "$ecr_repo:$tag"
    docker push "$ecr_repo:$tag"
fi
