#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

#set -o xtrace

NAMESPACE=ci-cd
scriptdir=$(dirname ${BASH_SOURCE[0]})
rootdir=${scriptdir}/..

source "${scriptdir}/_common.sh"

while getopts n:h name
do
    case $name in
    n)   if [[ -z "$OPTARG" ]] ; then echo "Error: empty namespace name" ; exit 1; fi
         NAMESPACE="$OPTARG";;
    h)   printf "Usage: %s: [-n NAMESPACE]\n" $0
         printf "  default NAMESPACE is $NAMESPACE\n"
          exit 1;;
    ?)   exit 1
    esac
done

MINISHIFT_IP=$(minishift ip)

echo "Installing in namespace $NAMESPACE on minishift at $MINISHIFT_IP"

oc login -u developer -p developer

echo "Building and loading images into Minishift..."
(eval $(minishift docker-env) ; cd images ; ./build.sh $NAMESPACE $(minishift openshift registry)/$NAMESPACE )

mkdir -p tmp
sed -e "s|MINISHIFT_IP|$MINISHIFT_IP|g" -e "s|NAMESPACE|$NAMESPACE|g" \
    configs/minishift-values.yaml > tmp/my-minishift-config.yaml

echo "Creating template file for minishift"
helm template helm-charts --name devops-stack --namespace $NAMESPACE --values tmp/my-minishift-config.yaml  > tmp/minishift-rendered.yaml

if [[ -z "${DEBUG_NO_INSTALL:-}" ]] ; then

    if oc get project | grep "$NAMESPACE" >/dev/null ; then
        echo "Looks like the CI-CD Stack is already installed:"
        oc get project
        exit 1
    fi

    oc new-project "$NAMESPACE" --description="Sample CICD stack tools - Gitea, Nexus and Jenkins" --display-name="DevOps Stack"
    oc --as=system:admin adm policy add-scc-to-user anyuid system:serviceaccount:$NAMESPACE:default

    echo "Installing the CI-CD stack..."
    oc create -f tmp/minishift-rendered.yaml

    if ! wait_deployments oc "${NAMESPACE}" 300 gitea nexus jenkins ; then
        echo "Still not ready after 5 minutes.  Something may be wrong, check output of 'oc get pods':"
        oc get pods
        exit 1
    else
        echo "CI-CD applications started:"
        echo "   http://git.$MINISHIFT_IP.nip.io/"
        echo "   http://nexus.$MINISHIFT_IP.nip.io/"
        echo "   http://jenkins.$MINISHIFT_IP.nip.io/"
    fi

fi
