#!/bin/bash

set -o errexit
set -o nounset

if [[ $# -ne 3 ]] ; then
    printf "Invalid parameters: "
    printf "'%s' " "$@"
    printf "\n\n"
    echo "Usage: $0 <ADS_BASE_URL> <NEXUS_BASE_URL> <ZEN_AUTHORIZATION>"
    exit 1
fi

if [[ "${DRY_RUN:-}" ]] ; then
   MVN=echo
else
   MVN=mvn
fi

ADS_BASE_URL=${1%/}  # chops trailing '/' from url
NEXUS_BASE_URL=${2%/}
ZEN_AUTHORIZATION=${3}

NEXUS_USER=${NEXUS_USER:=nexusdemo}
NEXUS_PASSWORD=${NEXUS_PASSWORD:=nexusdemo}

dir=$(dirname $0)
mkdir -p $dir/run
TMP_DIR=$dir/run

# check Nexus availability
NEXUS_STATUS=$(curl -s -k -w "%{http_code}" -u "$NEXUS_USER:$NEXUS_PASSWORD" "$NEXUS_BASE_URL/service/rest/v1/status" 2>&1 || true)
if [[ $NEXUS_STATUS == "200" ]] ; then
    echo "Nexus available at $NEXUS_BASE_URL"
else
    echo "ERROR: nexus not available at '$NEXUS_BASE_URL', http status $NEXUS_STATUS"
    exit 1
fi

sed "s|NEXUS_URL|${NEXUS_BASE_URL}|; s|NEXUS_USER|${NEXUS_USER}|; s|NEXUS_PASSWORD|${NEXUS_PASSWORD}|" \
    $dir/settings.xml.tpl > $TMP_DIR/settings.xml

# Fetch the index.json from download service
curl -k -s -H "Authorization: ZenApiKey $ZEN_AUTHORIZATION" -o run/index.json "$ADS_BASE_URL/index.json"

# for each artifact in json which has maven coordinates, upload
# the artifact into Nexus
jq --raw-output '.resources[]
    | select(has("maven_coordinates"))
    | [.path,
       .maven_coordinates.groupId,
       .maven_coordinates.artifactId,
       .maven_coordinates.version,
       .maven_coordinates.packaging,
	   .pom_path]
    | join(" ")' \
    run/index.json \
| while read -r -a artifact ; do
    url=$ADS_BASE_URL/${artifact[0]}
    echo "Downloading $url..."
    curl -k -s -H "Expect:" -H "Authorization: ZenApiKey $ZEN_AUTHORIZATION" --create-dirs -o run/${artifact[0]} "$url"
    # pom provided
    pom=${artifact[5]:-}
    if [[  ! -z ${pom} ]] ; then
        pomurl=$ADS_BASE_URL/${artifact[5]}
        echo "Downloading $pomurl..."
        curl -k -s -H "Authorization: ZenApiKey $ZEN_AUTHORIZATION" --create-dirs -o run/${artifact[5]} "$pomurl"
        echo "Uploading into Nexus as GAV provided by pom file '${artifact[5]}' ..."
        $MVN --batch-mode -s "$TMP_DIR/settings.xml" \
            -Dmaven.wagon.http.ssl.insecure=true \
            deploy:deploy-file \
            "-Dfile=run/${artifact[0]}" \
            -DpomFile="run/${artifact[5]}" \
            -DrepositoryId=maven-releases \
            -Durl=$NEXUS_BASE_URL/repository/maven-releases/
    else
        echo "Uploading into Nexus as ${artifact[1]}:${artifact[2]}:${artifact[3]}:${artifact[4]} ..."
        $MVN --batch-mode -s "$TMP_DIR/settings.xml" \
            -Dmaven.wagon.http.ssl.insecure=true \
            deploy:deploy-file \
            "-Dfile=run/${artifact[0]}" \
            -DgroupId="${artifact[1]}" \
            -DartifactId="${artifact[2]}" \
            -Dversion="${artifact[3]}" \
            -Dpackaging="${artifact[4]}" \
            -DrepositoryId=maven-releases \
            -Durl=$NEXUS_BASE_URL/repository/maven-releases/
    fi
done
