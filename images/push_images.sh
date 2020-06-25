#!/usr/bin/env bash

set -e

IMAGE_BASE_REPO=$1
usage() {
    echo "Usage: $(basename $0) <IMAGE_BASE_REPO>"
    echo "  IMAGE_BASE_REPO: prefix for repository name of the build images"
}

if [ -z "$IMAGE_BASE_REPO" ] ; then
    echo "Missing IMAGE_BASE_REPO parameter"
    usage
    exit 1
fi

docker push "$IMAGE_BASE_REPO/gitea:0.1.0"
docker push "$IMAGE_BASE_REPO/nexus:0.2.0"
