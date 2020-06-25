#!/bin/bash

set -e

IMAGE_BASE_REPO=$1
TARGET_CLUSTER=$2

usage() {
    echo "Usage: $(basename $0) <IMAGE_BASE_REPO>"
    echo "  IMAGE_BASE_REPO: prefix for repository name of the build images"
}

if [ -z "$IMAGE_BASE_REPO" ] ; then
    echo "Missing IMAGE_BASE_REPO parameter"
    usage
    exit 1
fi

BASE_DIR=$(dirname $0)

GITEA_IMG_VERSION=0.1.0
NEXUS_IMG_VERSION=0.2.0

echo "Builder gitea image..."
docker build -t "$IMAGE_BASE_REPO/gitea:$GITEA_IMG_VERSION" $BASE_DIR/gitea

echo "Builder nexus image..."
docker build -t "$IMAGE_BASE_REPO/nexus:$NEXUS_IMG_VERSION" $BASE_DIR/nexus

if [[ "$TARGET_CLUSTER" == "minikube" ]] ; then
    # pulling all images for gitea because values.yaml of gitea doesn't allow
    # to set "imagePullPolicy: Never" only for one image (the one built above)
    docker pull "postgres:11"
    docker pull "memcached:1.5.6-alpine"
fi
