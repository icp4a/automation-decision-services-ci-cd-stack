#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

IMAGE_REGISTRY=$1
PROJECT=$2
NEXUS_HOST=$3

sed -e "s|NEXUS_HOST|$NEXUS_HOST|g" \
    -e "s|IMAGE_REGISTRY|$IMAGE_REGISTRY|g" \
    -e "s|PROJECT|$PROJECT|g" \
    configs/openshift-values.yaml

