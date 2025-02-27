#!/usr/bin/env bash
set -euo pipefail

SH_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

# ci vars
echo "Getting CI vars"
source "${SH_DIR}/meta.sh"

# module vars
if test -f "${DEPLOY_DIR}/meta.sh"; then
  echo "Getting module vars"
  source "${DEPLOY_DIR}/meta.sh"
fi

# remote module vars
BASE_REMOTE_SRC="github.com/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}.git"
BASE_REMOTE_MOD_SRC="${BASE_REMOTE_SRC}//modules"
LATEST_REL_TAG="$(curl -sSfL -H "X-GitHub-Api-Version: 2022-11-28" -H "Accept: application/vnd.github+json" https://api.github.com/repos/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}/releases/latest | jq -r '.tag_name')"

deploy() {
  component=${1:-all}
  pushd "$DEPLOY_DIR" >/dev/null
  for tf_cmd in 'init' 'validate' 'apply'; do
    bash "./tf.sh" "$component" "$tf_cmd" || {
      echo "Terraform $tf_cmd failed. Exiting..."
      return 1
    }
  done
  popd >/dev/null 2>&1
}

set_ci_branch_name() {
  if [[ "$CIRCLE_BRANCH" =~ ^pull/[0-9]+/head$ ]]; then
    PR_NUMBER=$(echo "$CIRCLE_BRANCH" | sed -n 's/^pull\/\([0-9]*\)\/head/\1/p')
    ci_branch_name=$(curl -s \
      "https://api.github.com/repos/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}/pulls/${PR_NUMBER}" |
      jq -r .head.ref)
  else
    ci_branch_name="$CIRCLE_BRANCH"
  fi
  CI_BRANCH_NAME=$(jq -rn --arg br "$ci_branch_name" '$br|@uri')
  export CI_BRANCH_NAME
}

setup_module() {
  local deploy_dir="$1"
  local repo_ref="$2"

  rm -rf "$deploy_dir"
  mkdir -p "$deploy_dir"
  echo "Running init from module: -from-module=${BASE_REMOTE_SRC}//examples/deploy?ref=${repo_ref} at: $deploy_dir"
  terraform -chdir="$deploy_dir" init -backend=false -from-module="${BASE_REMOTE_SRC}//examples/deploy?ref=${repo_ref}"
}

setup_modules_ci_branch() {
  set_ci_branch_name
  setup_module "$DEPLOY_DIR" "$CI_BRANCH_NAME"
}

setup_modules_latest_rel() {
  setup_module "$DEPLOY_DIR" "$LATEST_REL_TAG"
}

install_helm() {
  if [ -z "$HELM_VERSION" ]; then
    echo "HELM_VERSION environment variable not set, exiting."
    exit 1
  fi
  echo "Installing Helm version: ${HELM_VERSION}"
  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  chmod +x get_helm.sh
  ./get_helm.sh --version "${HELM_VERSION}"
  rm ./get_helm.sh
  helm version --short
}

install_hcledit() {
  local hcledit_version="${HCLEDIT_VERSION}"
  local hcledit_artifact=hcledit_${hcledit_version}_linux_amd64.tar.gz
  curl -fsSL -o "${hcledit_artifact}" "https://github.com/minamijoyo/hcledit/releases/download/v${hcledit_version}/${hcledit_artifact}"
  tar xvzf "${hcledit_artifact}"
  sudo mv hcledit /usr/local/bin/ && rm "${hcledit_artifact}" && hcledit version
}

set_eks_worker_ami() {
  # We can potentially test AMI upgrades in CI.
  # 1 is latest.
  local precedence="$1"
  local k8s_version="$(grep 'k8s_version' $INFRA_VARS_TPL | awk -F'"' '{print $2}')"
  if ! aws sts get-caller-identity; then
    echo "Incorrect AWS credentials."
    exit 1
  fi
  CUSTOM_AMI="$(aws ec2 describe-images --region us-west-2 --owners '602401143452' --filters "Name=owner-alias,Values=amazon" "Name=architecture,Values=x86_64" "Name=name,Values=amazon-eks-node-${k8s_version// /}*" --query "sort_by(Images, &CreationDate) | [-${precedence}].ImageId" --output text)"
  export CUSTOM_AMI
}

set_tf_vars() {
  set_eks_worker_ami '1'
  if [ -z $CUSTOM_AMI ]; then
    echo 'CUSTOM_AMI is not set.'
    # We want to test passing an ami.
    exit 1
  fi

  [ -f "$PVT_KEY" ] || { ssh-keygen -q -P '' -t rsa -b 4096 -m PEM -f "$PVT_KEY" && chmod 600 "$PVT_KEY"; }

  export CUSTOM_AMI PVT_KEY
  local default_nodes=$(envsubst <"$INFRA_VARS_TPL" | tee "$INFRA_VARS" | hcledit attribute get default_node_groups)
  echo "default_node_groups = $default_nodes" >"$NODES_VARS"

  echo "Infra vars:" && cat "$INFRA_VARS"
  echo "Cluster vars:" && cat "$CLUSTER_VARS"
  echo "Nodes vars:" && cat "$NODES_VARS"
}

# Not used atm, but we could test nodes upgrades(OS-patches).
deploy_latest_ami_nodes() {
  ## Setting the default_node_groups.compute.ami to null ensures latest.
  export CUSTOM_AMI=null
  set_tf_vars
  deploy 'nodes'
}

destroy() {
  local component=${1:-all}
  pushd "$DEPLOY_DIR" >/dev/null
  bash "./tf.sh" "$component" destroy
  popd >/dev/null 2>&1
}

set_mod_src() {
  local mod_source="$1"
  local tf_file="$2"
  local name="$3"

  hcledit attribute set "module.${name}.source" "\"${mod_source}\"" -u -f "$tf_file"
  cat "$tf_file"
}

set_all_mod_src() {
  local ref="$1"
  local base_local_mod_src="./../../../../../modules"

  for dir in "${MOD_DIRS[@]}"; do
    local name
    if [[ "$dir" == *"cluster"* ]]; then
      name="eks"
    else
      name="$(basename $dir)"
    fi
    if [ "$ref" == "local" ]; then
      MOD_SOURCE="${base_local_mod_src}/${name}"
    else
      MOD_SOURCE="${BASE_REMOTE_MOD_SRC}/${name}?ref=${ref}"
    fi

    echo "Setting module source to ref: ${MOD_SOURCE} on ${dir}"
    set_mod_src "$MOD_SOURCE" "${dir}/main.tf" "$name"
  done
}

setup_single_node_tf() {
  echo "Setting up single_node module."
  local node_mod_dir="single-node"
  local BASE_TF_DIR="${DEPLOY_DIR}/terraform"
  local node_deploy_mod_dir="${BASE_TF_DIR}/${node_mod_dir}"

  mv "${node_mod_dir}/single-node.tfvars" "${BASE_TF_DIR}/single-node.tfvars"
  cat "${BASE_TF_DIR}/single-node.tfvars"
  cp -r "$node_mod_dir" "$node_deploy_mod_dir"

  set_ci_branch_name
  MOD_SOURCE="${BASE_REMOTE_MOD_SRC}/${node_mod_dir}?ref=${CI_BRANCH_NAME}"

  echo "Updating single_node mod source to ${MOD_SOURCE}..."
  set_mod_src "$MOD_SOURCE" "${node_deploy_mod_dir}/main.tf" "single_node"
}

deploy_single_node() {
  deploy "single-node"
}

destroy_single_node() {
  destroy "single-node"
}

set_mod_src_circle_branch() {
  set_ci_branch_name
  set_all_mod_src "$CI_BRANCH_NAME"
}

set_mod_src_local() {
  echo "Updating module source to local."
  set_all_mod_src "local"
}

set_mod_src_latest_rel() {
  echo "Updating module source to the latest published release: ${LATEST_REL_TAG}"
  set_all_mod_src "$LATEST_REL_TAG"
}

for arg in "$@"; do
  "$arg"
done
