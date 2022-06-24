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

NEXUS_IMG_VERSION=0.2.1

echo "Builder nexus image..."
docker build -t "$IMAGE_BASE_REPO/nexus:$NEXUS_IMG_VERSION" $BASE_DIR/nexus

