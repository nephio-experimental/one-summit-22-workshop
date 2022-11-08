#!/bin/bash
USER=${1:-}


if [[ ! ${USER} ]]
then
    USER=`groups | awk '{print $1}'`
else
    echo "Please provide user"
    exit 1
fi

function install_docker() {
    local USER="$1"	
    sudo apt-get -y update
    sudo apt-get -y install docker.io apt-transport-https make gcc cmake
    sudo systemctl enable docker.service    
    sudo usermod -aG docker ${USER}
    sudo chmod 777 /var/run/docker.sock
}

function install_kind() {
   curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64
   sudo chmod +x ./kind
   mkdir -p ${HOME}/.local/bin
   mv ./kind ${HOME}/.local/bin
   PATH=$PATH:${HOME}/.local/bin; export PATH
   echo $PATH

}

function install_k8s() {
   sudo su - -c  "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -"
   sudo su - -c "echo deb http://apt.kubernetes.io/ kubernetes-xenial main | tee /etc/apt/sources.list.d/kubernetes.list"
   sudo su - -c "apt-get update"
   sudo kubeadm reset -f
   sudo  apt install -y kubelet=1.20.0-00 kubeadm=1.20.0-00 kubectl=1.20.0-00
   sudo kubeadm init
   sudo rm -rf $HOME/.kube
   mkdir -p $HOME/.kube
   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   sudo chown $(id -u):$(id -g) $HOME/.kube/config
}

function install_weave() {
   kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
}


function install_multus() {
    cd $HOME	
    git clone https://github.com/intel/multus-cni.git
    cd multus-cni
    cat ./deployments/multus-daemonset-thick-plugin.yml | kubectl delete -f -
    cat ./deployments/multus-daemonset-thick-plugin.yml | kubectl apply -f -
}

function install_helm() {
    sudo rm -rf /usr/local/bin/helm
    ps -ef | grep -v grep | grep -iw helm | awk '{print $2}' | xargs kill -9    
    curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
    chmod 700 get_helm.sh
    sudo ./get_helm.sh -v v3.7.1
    kubectl taint nodes $(hostname) node-role.kubernetes.io/master-

}
function install_go() {
   cd $HOME
   sudo rm go1.19.3.linux-amd64.tar.gz
   sudo rm -rf $HOME/go
   sudo rm -rf /usr/local/go
   wget https://dl.google.com/go/go1.19.3.linux-amd64.tar.gz
   sudo tar -C /usr/local -zxvf go1.19.3.linux-amd64.tar.gz > /dev/null 2>&1
   mkdir -p ~/go/{bin,pkg,src}
}


echo "Installing Docker"
install_docker ${USER}
echo "Installing Kind"
install_kind
#echo "Installing k8s"
#install_k8s
echo "Installing weave CNI"
#install_weave
echo "Installing multus"
#install_multus
echo "Installing helm"
#install_helm
echo "Installing go"
install_go
