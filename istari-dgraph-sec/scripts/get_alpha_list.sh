#!/usr/bin/env bash

get_alpha_list() {
  ## No of replicas in Alpha statefulset
  REPLICAS=${REPLICAS:-"3"}
  ## helm release name
  RELEASE=${RELEASE:-"my-release"}
  ## namespace used during deployment
  NAMESPACE=${NAMESPACE:-"default"}
  ## Helm fullnameOverride (defaults to RELEASE-istari-dgraph-sec)
  FULLNAME=${FULLNAME:-"$RELEASE-istari-dgraph-sec"}

  ## Build List
  for (( IDX=0; IDX<REPLICAS; IDX++ )); do
    LIST+=("$FULLNAME-alpha-$IDX.$FULLNAME-alpha-headless.$NAMESPACE.svc")
  done

  ## Output Comma Separated List
  IFS=,; echo "${LIST[*]}"
}

get_alpha_list
