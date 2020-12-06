#!/bin/bash
set -eo pipefail
VERSION="${VERSION:=2.4.00}"

if [ ! -d "jsettlers-$VERSION-full" ]
then
  curl -sL "https://github.com/jdmonin/JSettlers2/releases/download/release-$VERSION/jsettlers-$VERSION-full.tar.gz" | tar xzf -
fi

if [ "$1" = "aks" ]
then
  . azure.env

  echo "Azure login..."
  az login

  if [ -z "$RG" ]
  then
    RG="rg$(uuidgen)"
    RG_LOC="westeurope"
    echo "Creating Resource Group $RG"
    az group create --name $RG --location $RG_LOC
  fi

  if [ -z "$CR" ]
  then
    CR="cr$(date +%N)"
    echo "Creating Container Registry $CR"
    az acr create --resource-group $RG --name $CR --sku Basic
    az acr login --name $CR
  fi

  if [ ! -f ~/.ssh/az_rsa.pub ]
  then
    echo "Generating SSH key for the k8s nodes"
    ssh-keygen -m PEM -t rsa -b 4096 -N '' -f ~/.ssh/az_rsa
  fi

  if [ -z "$KS" ]
  then
    KS="ks$(date +%Y%m%d)"
    echo "Creating Kubernetes Cluster $KS"
    pushd ~/.ssh
    az aks create \
      --resource-group $RG \
      --name $KS \
      --node-count 2 \
      --ssh-key-value "az_rsa.pub" \
      --attach-acr $CR
    popd
  fi

  if ! command -v kubectl &> /dev/null
  then
    echo "Installing kubectl command"
    az aks install-cli
  fi

  echo "Set up K8s environment"
  az aks get-credentials --resource-group $RG --name $KS -f az-k8s.kubeconf
  export KUBECONFIG=az-k8s.kubeconf

  echo "Building and Pushing application image"
  docker context use default
  docker build --build-arg APP_VER=$VERSION -t $CR.azurecr.io/jsettlers-server:$VERSION .
  docker push $CR.azurecr.io/jsettlers-server:$VERSION

  echo "Creating jsettle namespace"
  kubectl create -f aks-deploy/namespace.yaml

  echo "Deploying resources"
  cat aks-deploy/{app,db}-*.yaml | kubectl -n jsettlers create -f -

  # Wait for the db is ready and run sql scripts
  kubectl -n jsettlers rollout status deploy/db -w
  kubectl -n jsettlers exec -i deploy/db -- \
    sh -c 'mysql -p$MYSQL_ROOT_PASSWORD $MYSQL_DATABASE' \
    < jsettlers-$VERSION/src/main/bin/sql/jsettlers-tables-mysql.sql
  # Wait for the app is ready
  kubectl -n jsettlers rollout status deploy/app -w
else
  APP_VER=$VERSION docker-compose up -d --build
fi
