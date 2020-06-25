#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

NAMESPACE=default

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

MINIKUBE_IP=$(minikube ip)
HELM_RELEASE=ci-cd-demo

echo "Installing in namespace '$NAMESPACE' on minikube at $MINIKUBE_IP"

helm init --wait

if helm list | grep $HELM_RELEASE >/dev/null ; then
    echo "Looks like the CI-CD Stack is already installed:"
    helm list
    exit 1
fi

echo "Building and loading images into Minikube..."
(eval $(minikube docker-env) ; cd images ; ./build.sh $HELM_RELEASE minikube)

mkdir -p tmp
sed -e "s|MINIKUBE_IP|$MINIKUBE_IP|g" configs/minikube-values.yaml > tmp/my-minikube-config.yaml

echo "Installing the CI-CD stack... (may take a few minutes)"
helm install --wait helm-charts --name $HELM_RELEASE --namespace $NAMESPACE --values tmp/my-minikube-config.yaml

echo "CI-CD applications started:"
echo "   http://git.$MINIKUBE_IP.nip.io/"
echo "   http://nexus.$MINIKUBE_IP.nip.io/"
echo "   http://jenkins.$MINIKUBE_IP.nip.io/"
