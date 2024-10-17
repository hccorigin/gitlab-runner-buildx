#!/bin/bash
set -e


function reg_docker_executor {
    local GITLAB_TOKEN=$1
    local GITLAB_URL=$2
    local EXECUTOR_NAME=$3
    local DEFAULT_IMAGE=$4
    local TAG_LIST=$5
    local HELPER_IMAGE=$6

    gitlab-runner register \
        --executor docker \
        --non-interactive \
        --registration-token $GITLAB_TOKEN \
        --url $GITLAB_URL \
        --name $EXECUTOR_NAME \
        --docker-image $DEFAULT_IMAGE \
        --docker-volumes "/cache" \
        --docker-volumes "/var/run/docker.sock:/var/run/docker.sock" \
        --docker-network-mode gitlab_default \
        --tag-list $TAG_LIST \
        --docker-helper-image $HELPER_IMAGE
}


function reg_shell_executor {
    local GITLAB_TOKEN=$1
    local GITLAB_URL=$2
    local EXECUTOR_NAME=$3
    local TAG_LIST=$4
    
    gitlab-runner register \
        --executor shell \
        --non-interactive \
        --registration-token $GITLAB_TOKEN \
        --url $GITLAB_URL \
        --name $EXECUTOR_NAME \
        --tag-list $TAG_LIST
}

# Env variables
DEFAULT_IMAGE="hccorigin/gitlab-runner:17.4.1-amd64"
HELPER_IMG="gitlab/gitlab-runner-helper:x86_64-v17.4.1"
# "token" "gitlab-url" "name" "default-image" "tag-list" "helper-image" 
reg_docker_executor "token" "gitlab-url" "name" "default-image" "tag-list" "helper-image" 

# "token" "gitlab-url" "name" "tag-list"
reg_shell_executor  "token" "gitlab-url" "name" "tag-list"

