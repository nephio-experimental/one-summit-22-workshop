#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
export PATH=$PATH:~/.local/bin/:/usr/local/go/bin/

# This script holds common bash variables and utility functions.

ETCD_POD_LABEL="etcd"
KUBE_CONTROLLER_POD_LABEL="kube-controller-manager"

MIN_Go_VERSION=go1.16.0

# This function installs a Go tools by 'go install' command.
# Parameters:
#  - $1: package name, such as "sigs.k8s.io/controller-tools/cmd/controller-gen"
#  - $2: package version, such as "v0.4.1"
function util::install_tools() {
	local package="$1"
	local version="$2"

	GO111MODULE=on go install "${package}"@"${version}"
	GOPATH=$(go env GOPATH | awk -F ':' '{print $1}')
	export PATH=$PATH:$GOPATH/bin
}


function util::cmd_exist {
  local CMD=$(command -v ${1})
  if [[ ! -x ${CMD} ]]; then
    return 1
  fi
  return 0
}

# util::cmd_must_exist check whether command is installed.
function util::cmd_must_exist {
    echo "Checking ${1} exists"
    local CMD=$(command -v ${1})
    if [[ ! -x ${CMD} ]]; then
      echo "Please install ${1} and verify they are in \$PATH."
      exit 1
    fi
}

function util::verify_go_version {
    echo "Checking go Version"
    local go_version
    IFS=" " read -ra go_version <<< "$(GOFLAGS='' go version)"
    if [[ "${MIN_Go_VERSION}" != $(echo -e "${MIN_Go_VERSION}\n${go_version[2]}" | sort -s -t. -k 1,1 -k 2,2n -k 3,3n | head -n1) && "${go_version[2]}" != "devel" ]]; then
      echo "Detected go version: ${go_version[*]}."
      echo "Please install ${MIN_Go_VERSION} or later."
      exit 1
    fi
}

# util::install_environment_check will check OS and ARCH before installing
# ARCH support list: amd64,arm64
# OS support list: linux,darwin
function util::install_environment_check {
    local ARCH=${1:-}
    local OS=${2:-}
    if [[ "$ARCH" =~ ^(amd64|arm64)$ ]]; then
        if [[ "$OS" =~ ^(linux|darwin)$ ]]; then
            return 0
        fi
    fi
    echo "Sorry, installation does not support $ARCH/$OS at the moment"
    exit 1
}

# util::install_kubectl will install the given version kubectl
function util::install_kubectl {
    local KUBECTL_VERSION=${1}
    local ARCH=${2}
    local OS=${3:-linux}
    if [ -z "$KUBECTL_VERSION" ]; then
      KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    fi
    echo "Installing 'kubectl ${KUBECTL_VERSION}' for you"
    curl --retry 5 -sSLo ./kubectl -w "%{http_code}" https://dl.k8s.io/release/"$KUBECTL_VERSION"/bin/"$OS"/"$ARCH"/kubectl | grep '200' > /dev/null
    ret=$?
    if [ ${ret} -eq 0 ]; then
        chmod +x ./kubectl
        mkdir -p ~/.local/bin/
        mv ./kubectl ~/.local/bin/kubectl

        export PATH=$PATH:~/.local/bin
    else
        echo "Failed to install kubectl, can not download the binary file at https://dl.k8s.io/release/$KUBECTL_VERSION/bin/$OS/$ARCH/kubectl"
        exit 1
    fi
}

# util::install_kind will install the given version kind
function util::install_kind {
  local kind_version=${1}
  echo "Installing 'kind ${kind_version}' for you"
  local os_name
  os_name=$(go env GOOS)
  local arch_name
  arch_name=$(go env GOARCH)
  curl --retry 5 -sSLo ./kind -w "%{http_code}" "https://kind.sigs.k8s.io/dl/${kind_version}/kind-${os_name:-linux}-${arch_name:-amd64}" | grep '200' > /dev/null
  ret=$?
  if [ ${ret} -eq 0 ]; then
      chmod +x ./kind
      mkdir -p ~/.local/bin/
      mv ./kind ~/.local/bin/kind

      export PATH=$PATH:~/.local/bin
  else
      echo "Failed to install kind, can not download the binary file at https://kind.sigs.k8s.io/dl/${kind_version}/kind-${os_name:-linux}-${arch_name:-amd64}"
      exit 1
  fi
}
# util::append_client_kubeconfig creates a new context including a cluster and a user to the existed kubeconfig file
function util::append_client_kubeconfig {
    local kubeconfig_path=$1
    local client_certificate_file=$2
    local client_key_file=$3
    local api_host=$4
    local api_port=$5
    local client_id=$6
    local token=${7:-}
    kubectl config set-cluster "${client_id}" --server=https://"${api_host}:${api_port}" --insecure-skip-tls-verify=true --kubeconfig="${kubeconfig_path}"
    kubectl config set-credentials "${client_id}" --token="${token}" --client-certificate="${client_certificate_file}" --client-key="${client_key_file}" --embed-certs=true --kubeconfig="${kubeconfig_path}"
    kubectl config set-context "${client_id}" --cluster="${client_id}" --user="${client_id}" --kubeconfig="${kubeconfig_path}"
}

# util:: export_secret
function util::export_secret {
   local k1=$1
   local k2=$2
   local k3=$3
   local k4=$4
   echo "Setup remote secret in cluster"
   
   for ((k=1; k<5; k++)); do
	   for ((i=1; i<5; i++)); do
		if [ $i -ne $k ]; then 
	                tc=k${i} 
			sc=k${k}
	        	istioctl x create-remote-secret --kubeconfig=${!tc} --context=cluster${i} --name=kind-cluster${i} \
		       	|  kubectl apply -f - --kubeconfig=${!sc} --context=cluster${k} 
		fi
       	   sleep 1
    	done
   done
}

# util::setup_mp
function util::setup_mp {
    local kubeconfig=$1
    local context_name=$2
    local cluster_number=$3
    local istio_version=$4

    echo "Setup multi-primary in cluster${cluster_number}"

    #set the default networks
    kubectl --kubeconfig="${kubeconfig}" label namespace istio-system topology.istio.io/network=network${cluster_number}

    #configure cluster as primary
    cat << EOF | istioctl install --kubeconfig=${kubeconfig} --context=${context_name} -y -f -
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: kind-${context_name}
      network: network${cluster_number}
EOF
    #Install the east-west gateway
    pushd hack/bin/istio-${istio_version}
    samples/multicluster/gen-eastwest-gateway.sh \
    --mesh mesh1 --cluster kind-${context_name} --network network${cluster_number} | \
    istioctl  --kubeconfig=${kubeconfig} --context=${context_name} install -y -f -
    sleep 5

    #expose service in cluster
    kubectl  --kubeconfig=${kubeconfig} --context=${context_name} apply -n istio-system -f \
    samples/multicluster/expose-services.yaml
    popd
}

# util::install_metallb
function util::install_metallb {
    local kubeconfig=$1
    local cluster_number=$2
    echo "Setup metallb in cluster${cluster_number}"
    kubectl --kubeconfig=${kubeconfig} apply -f https://raw.githubusercontent.com/metallb/metallb/v0.7.3/manifests/namespace.yaml
    kubectl --kubeconfig=${kubeconfig} create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
    kubectl --kubeconfig=${kubeconfig} apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml
    util::wait_for_condition 'Running' "kubectl --kubeconfig ${kubeconfig} get pods -n metallb-system --selector=app=metallb --no-headers -o custom-columns=:status.phase" 300

    # setup address-pool
    ip=$(docker network inspect -f '{{.IPAM.Config}}' kind | awk '{n=split($0,a," "); print a[2]}')
    n1=$(echo $ip | awk '{n=split($0,a,"."); print a[1]}')
    n2=$(echo $ip | awk '{n=split($0,a,"."); print a[2]}')
    n3=$(expr ${cluster_number} \* 10 + 200)
    n4=$(expr $n3 + 9) 

    cat << EOF | kubectl --kubeconfig=${kubeconfig} apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - ${n1}.${n2}.255.${n3}-${n1}.${n2}.255.${n4}
EOF

   sleep 10
}

# util::install_istio will install the given version kind
function util::install_istiolib {
  local istio_version=${1}
  echo "Installing 'istio ${istio_version}' for you"
  local arch_name
  arch_name=$(go env GOARCH)
  ISTIO_VERSION=${istio_version}
  TARGET_ARCH=${arch_name:-x86_64}
  pushd hack/bin
  curl -sL https://istio.io/downloadIstio | ISTIO_VERSION=${istio_version} TARGET_ARCH=x86_64 sh
  ret=$?
  if [ ${ret} -eq 0 ]; then
      mkdir -p ~/.local/bin/
      cp ./istio-${istio_version}/bin/istioctl ~/.local/bin/istioctl

      export PATH=$PATH:~/.local/bin

      # create rootca certificate
      mkdir -p istio-${istio_version}/certs
      pushd istio-${istio_version}/certs

      make -f ../tools/certs/Makefile.selfsigned.mk root-ca
      popd

  else
      echo "Failed to install istio, can not download istio-${istio_version} for ${arch_name:-amd64}"
      exit 1
  fi
  popd
}


# util::setup in the provided cluser
function util::setup_istio {
    local kubeconfig=${1}
    local context_name=${2}
    local log_path=${3}
    local istio_version=${4}

    #generate intermediate CA cert for the cluster
    pushd hack/bin/istio-${istio_version}/certs
    make -f ../tools/certs/Makefile.selfsigned.mk kind-${context_name}-cacerts

    kubectl --kubeconfig ${kubeconfig} create namespace istio-system
    kubectl --kubeconfig ${kubeconfig} create secret generic cacerts -n istio-system \
      --from-file=kind-${context_name}/ca-cert.pem \
      --from-file=kind-${context_name}/ca-key.pem \
      --from-file=kind-${context_name}/root-cert.pem \
      --from-file=kind-${context_name}/cert-chain.pem
    popd
}

function util::install_istio {
    local kubeconfig=${1}
    local context_name=${2}
    local log_path=${3}
    local istio_version=${4}
    nohup yes y | istioctl install --set profile=demo --kubeconfig=${kubeconfig} --context=${context_name} >> "${log_path}"/"${context_name}".log 2>&1 & 
    echo "Installing Istio in ${context_name}"

    sleep 1

    # waith for istio install
    #kubectl config use-context ${context_name}
    util::wait_for_condition 'Running' "kubectl --kubeconfig ${kubeconfig} get pods -n istio-system --selector=app=istio-ingressgateway --no-headers -o custom-columns=:status.phase" 300

}

function util::inject_istio_sidecar {
    local kubeconfig=${1}
    local context_name=${2}
    local log_path=${3}
    local istio_version=${4}
    local namespace=${5}
    
    #enable istio sidecar injection in default ns
    kubectl  --kubeconfig ${kubeconfig} label namespace ${namespace} istio-injection=enabled

}

function util::setup_macvlan {
    local kubeconfig=${1}
    local context_name=${2}
    # Copying mac-vlan binary
    pushd hack/bin 
    sudo docker cp bin/ ${context_name}-control-plane:/opt/cni/
    popd
}

function util::install_weave() {
   echo "weaving"
   local kubeconfig=${1}
   local context_name=${2}
   echo ${kubeconfig}
   echo ${context_name}
   kubectl --kubeconfig ${kubeconfig} apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
}

function util::install_multus() {
    local kubeconfig=${1}
    local context_name=${2}
    # I am using * in cat command below to handle case where multus-daemonset-thick file may be named multus-daemonset-thick-plugin.yml -- vish 
    if [[ -d ${HOME}/multus-cni ]]
    then
        cat ${HOME}/multus-cni/deployments/multus-daemonset-thick*.yml | kubectl --kubeconfig ${kubeconfig} apply -f -
    else
        git -C ${HOME} clone https://github.com/intel/multus-cni.git 
        cat ${HOME}/multus-cni/deployments/multus-daemonset-thick*.yml | kubectl --kubeconfig ${kubeconfig} apply -f -
    fi
}


# util::wait_for_condition blocks until the provided condition becomes true
# Arguments:
#  - 1: message indicating what conditions is being waited for (e.g. 'ok')
#  - 2: a string representing an eval'able condition.  When eval'd it should not output
#       anything to stdout or stderr.
#  - 3: optional timeout in seconds. If not provided, waits forever.
# Returns:
#  1 if the condition is not met before the timeout
function util::wait_for_condition() {
  local msg=$1
  # condition should be a string that can be eval'd.
  local condition=$2
  local timeout=${3:-}

  local start_msg="Waiting for ${msg}"
  local error_msg="[ERROR] Timeout waiting for ${msg}"

  local counter=0
  while ! eval ${condition} | grep ${msg}; do
    if [[ "${counter}" = "0" ]]; then
      echo -n "${start_msg}"
    fi

    if [[ -z "${timeout}" || "${counter}" -lt "${timeout}" ]]; then
      counter=$((counter + 1))
      if [[ -n "${timeout}" ]]; then
        echo -n '.'
      fi
      sleep 1
    else
      echo -e "\n${error_msg}"
      return 1
    fi
  done

  if [[ "${counter}" != "0" && -n "${timeout}" ]]; then
    echo ' done'
  fi
}

# util::wait_file_exist checks if a file exists, if not, wait until timeout
function util::wait_file_exist() {
    local file_path=${1}
    local timeout=${2}
    for ((time=0; time<${timeout}; time++)); do
        if [[ -e ${file_path} ]]; then
            return 0
        fi
        sleep 1
    done
    return 1
}


# util::create_cluster creates a kubernetes cluster
# util::create_cluster creates a kind cluster and don't wait for control plane node to be ready.
# Parmeters:
#  - $1: cluster name, such as "host"
#  - $2: KUBECONFIG file, such as "/var/run/host.config"
#  - $3: node docker image to use for booting the cluster, such as "kindest/node:v1.19.1"
#  - $4: log file path, such as "/tmp/logs/"
function util::create_cluster() {
  local cluster_name=${1}
  local kubeconfig=${2}
  local kind_image=${3}
  local log_path=${4}
  local cluster_config=${5:-}

  mkdir -p ${log_path}
  rm -rf "${log_path}/${cluster_name}.log"
  rm -f "${kubeconfig}"
  nohup kind delete cluster --name="${cluster_name}" >> "${log_path}"/"${cluster_name}".log 2>&1 && kind create cluster --name "${cluster_name}" --kubeconfig="${kubeconfig}" --image="${kind_image}" --config="${cluster_config}" >> "${log_path}"/"${cluster_name}".log 2>&1 &
  echo "Creating cluster ${cluster_name}"
}

# This function returns the IP address of a docker instance
# Parameters:
#  - $1: docker instance name

function util::get_docker_native_ipaddress(){
  local container_name=$1
  docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "${container_name}"
}

# This function returns the IP address and port of a specific docker instance's host IP
# Parameters:
#  - $1: docker instance name
# Note:
#   Use for getting host IP and port for cluster
#   "6443/tcp" assumes that API server port is 6443 and protocol is TCP

function util::get_docker_host_ip_port(){
  local container_name=$1
  docker inspect --format='{{range $key, $value := index .NetworkSettings.Ports "6443/tcp"}}{{if eq $key 0}}{{$value.HostIp}}:{{$value.HostPort}}{{end}}{{end}}' "${container_name}"
}

# util::check_clusters_ready checks if a cluster is ready, if not, wait until timeout
function util::check_clusters_ready() {
  local kubeconfig_path=${1}
  local context_name=${2}

  echo "Waiting for kubeconfig file ${kubeconfig_path} and clusters ${context_name} to be ready..."
  util::wait_file_exist "${kubeconfig_path}" 300
  util::wait_for_condition 'running' "docker inspect --format='{{.State.Status}}' ${context_name}-control-plane" 300

  sleep 5 
  kubectl config rename-context "kind-${context_name}" "${context_name}" --kubeconfig="${kubeconfig_path}"

  local os_name
  os_name=$(go env GOOS)
  local container_ip_port
  case $os_name in
    linux) container_ip_port=$(util::get_docker_native_ipaddress "${context_name}-control-plane")":6443"
    ;;
    darwin) container_ip_port=$(util::get_docker_host_ip_port "${context_name}-control-plane")
    ;;
    *)
        echo "OS ${os_name} does NOT support for getting container ip in installation script"
        exit 1
  esac
  kubectl config set-cluster "kind-${context_name}" --server="https://${container_ip_port}" --kubeconfig="${kubeconfig_path}"

  util::wait_for_condition 'ok' "kubectl --kubeconfig ${kubeconfig_path} --context ${context_name} get --raw=/healthz" 300
}

# util::wait_service_external_ip give a service external ip when it is ready, if not, wait until timeout
# Parameters:
#  - $1: service name in k8s
#  - $2: namespace
SERVICE_EXTERNAL_IP=''
function util::wait_service_external_ip() {
  local service_name=$1
  local namespace=$2
  local external_ip
  local tmp
  for tmp in {1..30}; do
    set +e
    external_ip=$(kubectl get service "${service_name}" -n "${namespace}" --template="{{range .status.loadBalancer.ingress}}{{.ip}} {{end}}" | xargs)
    set -e
    if [[ -z "$external_ip" ]]; then
      echo "wait the external ip of ${service_name} ready..."
      sleep 6
      continue
    else
      SERVICE_EXTERNAL_IP="${external_ip}"
      return 0
    fi
  done
  return 1
}

# util::get_load_balancer_ip get a valid load balancer ip from k8s service's 'loadBalancer' , if not, wait until timeout
# call 'util::wait_service_external_ip' before using this function
function util::get_load_balancer_ip() {
  local tmp
  local first_ip
  if [[ -n "${SERVICE_EXTERNAL_IP}" ]]; then
    first_ip=$(echo "${SERVICE_EXTERNAL_IP}" | awk '{print $1}') #temporarily choose the first one
    for tmp in {1..10}; do
      set +e
      connect_test=$(curl -s -k -m 5 https://"${first_ip}":5443/readyz)
      set -e
      if [[ "${connect_test}" = "ok" ]]; then
        echo "${first_ip}"
        return 0
      else
        sleep 3
        continue
      fi
    done
  fi
  return 1
}
