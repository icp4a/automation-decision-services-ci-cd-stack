#!/usr/bin/env bash

set -o errexit
set -o nounset

loc=${BASH_SOURCE%/*}

( cd "${loc}/../images/ads-postinst/" && docker build -t ads-postinstall:latest . )

docker run ads-postinstall:latest "$@"
