#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

# Parameters: [HOST_IPADDRESS](optional) if you want to export clusters' API server port to specific IP address
# This script depends on utils in: ${REPO_ROOT}/hack/util.sh
# 1. used by developer to setup develop environment quickly.
# 2. used by e2e testing to setup test environment automatically.

source ./hack/util.sh

# variable define
KUBECONFIG_PATH=${KUBECONFIG_PATH:-"${HOME}/.kube"}
# hardcode the following
F5GCNI_SETUP="YES"
SETUP_METALLB="INSTALL_METALLB"
NUM_CLUSTERS=${1:-4}
CLUSTER_VERSION=${CLUSTER_VERSION:-"kindest/node:v1.21.1"}
KIND_LOG_FILE=${KIND_LOG_FILE:-"/tmp/targetClusters"}

# Make sure go exists and the go version is a viable version.
util::cmd_must_exist "go"
util::verify_go_version

# install kind and kubectl
kind_version=v0.11.1
echo -n "Preparing: 'kind' existence check - "
if util::cmd_exist kind; then
  echo "passed"
else
  echo "not pass"
  util::install_kind $kind_version
fi
# get arch name and os name in bootstrap
BS_ARCH=$(go env GOARCH)
BS_OS=$(go env GOOS)
# check arch and os name before installing
util::install_environment_check "${BS_ARCH}" "${BS_OS}"
echo -n "Preparing: 'kubectl' existence check - "
if util::cmd_exist kubectl; then
  echo "passed"
else
  echo "not pass"
  util::install_kubectl "" "${BS_ARCH}" "${BS_OS}"
fi
#prepare for kindClusterConfig
TEMP_PATH=$(mktemp -d)
echo -e "Preparing kindClusterConfig in path: ${TEMP_PATH}"
i=1
while [ "$i" -le "$NUM_CLUSTERS" ];
do
  FILE="${TEMP_PATH}"/cluster${i}.yaml	
cat << EOF > "$FILE"
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  podSubnet: "{{pod_subnet}}"
  serviceSubnet: "{{service_subnet}}"
featureGates:
  EndpointSliceProxying: true
nodes:
  - role: control-plane
EOF

  #1. Set kind cluster configuration
  POD_SUBNET="10.$(( i + 10 )).0.0\/16"
  SERVICE_SUBNET="10.$(( i + 11 )).0.0\/16"
  sed -i'' -e "s/{{pod_subnet}}/${POD_SUBNET}/g" "${TEMP_PATH}"/cluster${i}.yaml
  sed -i'' -e "s/{{service_subnet}}/${SERVICE_SUBNET}/g" "${TEMP_PATH}"/cluster${i}.yaml

  #2. Create Cluster
  util::create_cluster "cluster${i}" "${KUBECONFIG_PATH}/cluster${i}.config" "${CLUSTER_VERSION}" "${KIND_LOG_FILE}" "${TEMP_PATH}"/cluster${i}.yaml

  #wait until the host cluster ready
  echo "Waiting for the host clusters to be ready..."
  util::check_clusters_ready "${KUBECONFIG_PATH}/cluster${i}.config" "cluster${i}"

  #3. Install metallb
  if [[ ${SETUP_METALLB} == "INSTALL_METALLB" ]]; then
    util::install_metallb "${KUBECONFIG_PATH}/cluster${i}.config" ${i} 
  fi
  
  #4. Install CNIs
  if [[ -n "${F5GCNI_SETUP}" ]]; then
    #step5. Install Weave and multus CNI and copying the macvlan binary to kind container
    util::install_weave "${KUBECONFIG_PATH}/cluster${i}.config" "cluster${i}" 
    util::install_multus "${KUBECONFIG_PATH}/cluster${i}.config" "cluster${i}"
    #util::setup_macvlan "${KUBECONFIG_PATH}/cluster${i}.config" "cluster${i}"
  fi

  i=$(( i + 1 ))
done

