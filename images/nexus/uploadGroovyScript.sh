#!/bin/bash

set -e

scriptName=$1
groovyFile=$2

NEXUS_USER=${NEXUS_USER:-admin}
NEXUS_PASSWORD=${NEXUS_PASSWORD:-admin123}

[ -z "$NEXUS_BASEURL" ] && echo "Missing NEXUS_BASEURL env variable" && exit 1
[ -z "$scriptName" ] && echo "Missing scriptName param" && exit 1
[ -z "$groovyFile" ] && echo "Missing groovyFile param" && exit 1

EXISTS_CODE=$(curl -s -k -u "$NEXUS_USER:$NEXUS_PASSWORD" -o /dev/null -w "%{http_code}" "$NEXUS_BASEURL/service/rest/v1/script/$scriptName")
if [ "200" -eq "$EXISTS_CODE" ] ; then
    printf "Updating Integration API Script $scriptName from $groovyFile on $NEXUS_BASEURL\n\n"
    VERB=PUT
    RESOURCE=$scriptName
else
    printf "Creating Integration API Script $scriptName from $groovyFile on $NEXUS_BASEURL\n\n"
    VERB=POST
    RESOURCE=""
fi

jq -n --arg name "$scriptName" --arg program "$(cat $groovyFile)" \
   '{ "name": $name, "type": "groovy", "content": $program }'  \
   | curl -k -u "$NEXUS_USER:$NEXUS_PASSWORD" -X $VERB --header "Content-Type: application/json" \
     "$NEXUS_BASEURL/service/rest/v1/script/$RESOURCE" -d @-
