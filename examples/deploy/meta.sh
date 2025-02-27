#!/usr/bin/env bash

SH_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

BASE_TF_DIR="${SH_DIR}/terraform"
declare -a MOD_DIRS=(
  "${BASE_TF_DIR}/infra"
  "${BASE_TF_DIR}/cluster"
  "${BASE_TF_DIR}/nodes"
)

INFRA_DIR="${MOD_DIRS[0]}"
CLUSTER_DIR="${MOD_DIRS[1]}"
NODES_DIR="${MOD_DIRS[2]}"

CLUSTER_STATE="${BASE_TF_DIR}/cluster.tfstate"
NODES_STATE="${BASE_TF_DIR}/nodes.tfstate"
INFRA_STATE="${BASE_TF_DIR}/infra.tfstate"

CLUSTER_VARS="${BASE_TF_DIR}/cluster.tfvars"
NODES_VARS="${BASE_TF_DIR}/nodes.tfvars"
INFRA_VARS="${BASE_TF_DIR}/infra.tfvars"

export BASE_TF_DIR \
  MOD_DIRS \
  INFRA_DIR \
  CLUSTER_DIR \
  NODES_DIR \
  CLUSTER_STATE \
  NODES_STATE \
  INFRA_STATE \
  CLUSTER_VARS \
  NODES_VARS \
  INFRA_VARS
