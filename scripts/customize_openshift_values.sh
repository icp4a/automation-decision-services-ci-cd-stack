#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

IMAGE_REGISTRY=$1
PROJECT=$2
GIT_HOST=$3
NEXUS_HOST=$4
JENKINS_HOST=$5

sed -e "s|GIT_HOST|$GIT_HOST|g" \
    -e "s|NEXUS_HOST|$NEXUS_HOST|g" \
    -e "s|JENKINS_HOST|$JENKINS_HOST|g" \
    -e "s|IMAGE_REGISTRY|$IMAGE_REGISTRY|g" \
    -e "s|PROJECT|$PROJECT|g" \
    configs/openshift-values.yaml

