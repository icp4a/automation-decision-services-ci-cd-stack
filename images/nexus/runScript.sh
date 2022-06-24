#!/bin/bash

set -e

scriptName=$1
username=$2
password=$3

NEXUS_USER=${NEXUS_USER:-admin}
NEXUS_PASSWORD=${NEXUS_PASSWORD:-admin123}

[ -z "$NEXUS_BASEURL" ] && echo "Missing NEXUS_BASEURL env variable" && exit 1
[ -z "$scriptName" ] && echo "Missing scriptName param" && exit 1


jq -n --arg username "$username" --arg password "$password" --argjson roles '["nx-admin"]' \
        '{ "username": $username, "password": $password, "roles": $roles }'  \
    | curl -k -u "$NEXUS_USER:$NEXUS_PASSWORD" \
     --header "Content-Type: text/plain" \
     "$NEXUS_BASEURL/service/rest/v1/script/$scriptName/run" -d @-
