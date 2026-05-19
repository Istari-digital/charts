#!/usr/bin/env bash

get_alpha_list() {
  ## No of replicas in Alpha statefulset
  REPLICAS=${REPLICAS:-"3"}
  ## helm release name
  RELEASE=${RELEASE:-"my-release"}
  ## namespace used during deployment
  NAMESPACE=${NAMESPACE:-"default"}
  ## Helm fullnameOverride. Default mirrors dgraph.fullname (printf "%s-%s" Release.Name Chart.Name | trunc 24).
  FULLNAME=${FULLNAME:-"$(printf '%s-%s' "$RELEASE" "istari-dgraph-sec" | cut -c1-24)"}

  ## Build List
  for (( IDX=0; IDX<REPLICAS; IDX++ )); do
    LIST+=("$FULLNAME-alpha-$IDX.$FULLNAME-alpha-headless.$NAMESPACE.svc")
  done

  ## Output Comma Separated List
  IFS=,; echo "${LIST[*]}"
}

get_alpha_list
