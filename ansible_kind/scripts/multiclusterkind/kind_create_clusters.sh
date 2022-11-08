#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

# Parameters: [HOST_IPADDRESS](optional) if you want to export clusters' API server port to specific IP address
# This script depends on utils in: ${REPO_ROOT}/hack/util.sh
# 1. used by developer to setup develop environment quickly.
# 2. used by e2e testing to setup test environment automatically.

REPO_ROOT=$(dirname "${BASH_SOURCE[0]}")
source "${REPO_ROOT}"/hack/util.sh

# variable define
KUBECONFIG_PATH=${KUBECONFIG_PATH:-"${HOME}/.kube"}
ISTIO_SETUP_COMPLETE=""
# hardcode the following
F5GCNI_SETUP="YES"
ISTIO_SETUP_METALLB="INSTALL_METALLB"
NUM_CLUSTERS=${1:-4}
HOST_IPADDRESS=${2:-}

############
#echo "Enter Host IP: .. <optional>"
#read HOST_IPADDRESS

#echo "Number of Clusters:" 
#read NUM_CLUSTERS
#if [[ -z $NUM_CLUSTERS ]]; then
#         echo "provide number of clusters to be created."
#         exit 1
#fi
#
#while true; do
#    read -p "Do you wish to install CNI for Free5GC? " yn
#    case $yn in
#        [Yy]* ) 
#             F5GCNI_SETUP="YES"; 
#             ;;
#        [Nn]* )
#             F5GCNI_SETUP=""
#             ;;
#        * ) echo "Please answer yes or no.";;
#    esac
#    read -p "Do you wish to install ISTIO? " yn
#    case $yn in
#        [Yy]* )
#             ISTIO_SETUP_COMPLETE="ISTIO_COMPLETE_INSTALL";
#             ISTIO_SETUP_METALLB="INSTALL_METALLB";
#             break
#             ;;
#        [Nn]* )
#             ISTIO_SETUP_COMPLETE=""
#             ;;
#        * ) echo "Please answer yes or no.";;
#    esac
#    read -p "Do you wish to install METALLB? " yn
#    case $yn in
#        [Yy]* )
#             ISTIO_SETUP_METALLB="INSTALL_METALLB";
#             break
#             ;;
#        [Nn]* )
#             ISTIO_SETUP_METALLB=""
#             break
#             ;;
#        * ) echo "Please answer yes or no.";;
#    esac
#done
###############

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
CLUSTER_PORT=15023
echo -e "Preparing kindClusterConfig in path: ${TEMP_PATH}"
i=1
while [ "$i" -le $NUM_CLUSTERS ];
do
  cp -rf "${REPO_ROOT}"/kindClusterConfig/cluster.yaml "${TEMP_PATH}"/cluster${i}.yaml
  cp -rf "${REPO_ROOT}"/kindClusterConfig/cluster_provider.json "${TEMP_PATH}"/cluster_provider.json

  #1. Set kind cluster configuration
  POD_SUBNET="10.`expr $i + 10`.0.0\/16"
  SERVICE_SUBNET="10.`expr $i + 11`.0.0\/16"
  sed -i'' -e "s/{{pod_subnet}}/${POD_SUBNET}/g" "${TEMP_PATH}"/cluster${i}.yaml
  sed -i'' -e "s/{{service_subnet}}/${SERVICE_SUBNET}/g" "${TEMP_PATH}"/cluster${i}.yaml
  if [[ -n "${HOST_IPADDRESS}" ]]; then # If bind the port of clusters(cluster1, cluster2, cluster3 and cluster4) to the host IP
    sed -i'' -e "s/{{host_ipaddress}}/${HOST_IPADDRESS}/g" "${TEMP_PATH}"/cluster${i}.yaml
    sed -i'' -e 's/networking:/&\'$'\n''  apiServerAddress: "'${HOST_IPADDRESS}'"/' "${TEMP_PATH}"/cluster${i}.yaml
    sed -i'' -e 's/networking:/&\'$'\n''  apiServerPort: '`expr ${CLUSTER_PORT} + ${i} \* 3`'/' "${TEMP_PATH}"/cluster${i}.yaml
  else
    sed -i'' -e "/{{host_ipaddress}}/d" "${TEMP_PATH}"/cluster${i}.yaml
  fi

  #2. Create Cluster
  util::create_cluster "cluster${i}" "${KUBECONFIG_PATH}/cluster${i}.config" "${CLUSTER_VERSION}" "${KIND_LOG_FILE}" "${TEMP_PATH}"/cluster${i}.yaml

  #wait until the host cluster ready
  echo "Waiting for the host clusters to be ready..."
  util::check_clusters_ready "${KUBECONFIG_PATH}/cluster${i}.config" "cluster${i}"

  #3. Install metallb
  if [[ ${ISTIO_SETUP_METALLB} == "INSTALL_METALLB" ]]; then
    util::install_metallb "${KUBECONFIG_PATH}/cluster${i}.config" ${i} 
  fi
  
  #4. Install CNIs
  if [[ -n "${F5GCNI_SETUP}" ]]; then
    #step5. Install Weave and multus CNI and copying the macvlan binary to kind container
    util::install_weave "${KUBECONFIG_PATH}/cluster${i}.config" "cluster${i}" 
    util::install_multus "${KUBECONFIG_PATH}/cluster${i}.config" "cluster${i}"
    #util::setup_macvlan "${KUBECONFIG_PATH}/cluster${i}.config" "cluster${i}"
  fi

  # Install ISTIO - for service discovery
  if [[ ${ISTIO_SETUP_COMPLETE} == "ISTIO_COMPLETE_INSTALL" ]] ; then
    istio_version=1.12.1
	echo -n "Preparing: 'istio' existence check - "
	if util::cmd_exist istioctl; then
		echo "Istio Present alreadu"
	else
		util::install_istiolib $istio_version 
	fi
    #step3. Install Istio in clusters
    util::setup_istio "${KUBECONFIG_PATH}/cluster${i}.config" "cluster${i}" "${KIND_LOG_FILE}" "${istio_version}"

    #step4. Install Istio in clusters
    util::install_istio "${KUBECONFIG_PATH}/cluster${i}.config" "cluster${i}" "${KIND_LOG_FILE}" "${istio_version}"

    #step5. Install multi-primary
    util::setup_mp "${KUBECONFIG_PATH}/cluster${i}.config" "cluster${i}"  1 "${istio_version}"

    #step6: enable endpoint discovery
    #util::export_secret "${CLUSTER1_KUBECONFIG}" "${CLUSTER2_KUBECONFIG}" \
    #                       "${CLUSTER3_KUBECONFIG}" "${CLUSTER4_KUBECONFIG}"
  fi

  i=`expr $i + 1`
  echo $PWD
done

