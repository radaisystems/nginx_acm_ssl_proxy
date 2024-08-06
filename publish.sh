#!/bin/bash

set -euo pipefail

workspace=$1
ecr_repo=$2

if [ "$workspace" == "master" ]; then
    tag="latest"
elif [ "$workspace" == "prod" ]; then
    tag="v1"
else
    tag="test-migration"
fi


if [ "$workspace" == "master" ] || [ "$workspace" == "prod" ] || [ "$workspace" == "vishad/PLE-1877" ]; then
    docker login artifacts.radai.com -u "$ARTIFACTORY_USERNAME" -p "$ARTIFACTORY_PASSWORD"
    docker tag nginx-dynamic-acm artifacts.radai.com/local-platform-container-release/nginx/radai_nginx_dynamic_acm:"$tag"
    docker push artifacts.radai.com/local-platform-container-release/nginx/radai_nginx_dynamic_acm:"$tag"

    aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 659386482123.dkr.ecr.us-west-2.amazonaws.com
    docker tag nginx-dynamic-acm "$ecr_repo:$tag"
    docker push "$ecr_repo:$tag"
fi
