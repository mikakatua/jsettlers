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

  echo -e "\nAzure login..."
  az login

  if [ -z "$RG" ]
  then
    RG="rg$(uuidgen)"
    RG_LOC="westeurope"
    echo -e "\nCreating Resource Group $RG"
    az group create --name $RG --location $RG_LOC
  fi

  if [ -z "$CR" ]
  then
    CR="cr$(date +%N)"
    echo -e "\nCreating Container Registry $CR"
    az acr create --resource-group $RG --name $CR --sku Basic
    az acr login --name $CR
  fi

  if [ ! -f ~/.ssh/az_rsa.pub ]
  then
    echo -e "\nGenerating SSH key for the k8s nodes"
    ssh-keygen -m PEM -t rsa -b 4096 -N '' -f ~/.ssh/az_rsa
  fi

  if [ -z "$KS" ]
  then
    KS="ks$(date +%Y%m%d)"
    echo -e "\nCreating Kubernetes Cluster $KS"
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
    echo -e "\nInstalling kubectl command"
    az aks install-cli
  fi

  echo -e "\nSet up K8s environment"
  rm -f /tmp/az-k8s.kubeconf
  az aks get-credentials --resource-group $RG --name $KS -f /tmp/az-k8s.kubeconf
  export KUBECONFIG=/tmp/az-k8s.kubeconf

  echo -e "\nBuilding and Pushing application image"
  docker context use default
  docker build --build-arg APP_VER=$VERSION -t $CR.azurecr.io/jsettlers-server:$VERSION .
  docker push $CR.azurecr.io/jsettlers-server:$VERSION

  echo -e "\nCreating jsettle namespace"
  kubectl create -f aks-deploy/namespace.yaml

  echo -e "\nDeploying resources"
  cat aks-deploy/{app,db}-*.yaml | kubectl -n jsettlers create -f -

  # Wait for the db is ready and run sql scripts
  kubectl -n jsettlers rollout status deploy/db -w
  until kubectl -n jsettlers exec deploy/db -- sh -c 'mysqladmin -p$MYSQL_ROOT_PASSWORD ping' | grep -q 'mysqld is alive'
  do
    sleep 5
  done
  kubectl -n jsettlers exec -i deploy/db -- \
    sh -c 'mysql -p$MYSQL_ROOT_PASSWORD $MYSQL_DATABASE' \
    < jsettlers-$VERSION/src/main/bin/sql/jsettlers-tables-mysql.sql

  # Wait for the app is ready
  kubectl -n jsettlers rollout status deploy/app -w
  kubectl -n jsettlers get all

else
  APP_VER=$VERSION docker-compose up -d --build
fi
