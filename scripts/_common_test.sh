#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

set -o xtrace

scriptdir=$(dirname ${BASH_SOURCE[0]})
rootdir=${scriptdir}/..

source $scriptdir/_common.sh

DEBUG=1

wait_deployments oc ci-cd 30 nexus
