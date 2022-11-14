#!/bin/bash

function install_docker() {
    sudo apt-get -y update
    sudo apt-get -y install docker.io apt-transport-https make gcc cmake
    sudo systemctl enable docker.service
    sudo usermod -aG docker "${USER:-ubuntu}"
    sudo chmod 777 /var/run/docker.sock
}

function install_kind() {
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64
    sudo chmod +x ./kind
    mkdir -p "${HOME}"/.local/bin
    mv ./kind "${HOME}"/.local/bin
}

function install_go() {
    cd "$HOME" || exit
    sudo rm go1.19.3.linux-amd64.tar.gz
    sudo rm -rf "$HOME"/go
    sudo rm -rf /usr/local/go
    wget https://dl.google.com/go/go1.19.3.linux-amd64.tar.gz
    sudo tar -C /usr/local -zxvf go1.19.3.linux-amd64.tar.gz >/dev/null 2>&1
    mkdir -p ~/go/{bin,pkg,src}

    sudo mkdir -p /etc/profile.d/
    # shellcheck disable=SC2016
    echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/path.sh >/dev/null

    echo fs.inotify.max_user_watches=655360 | sudo tee -a /etc/sysctl.conf
    echo fs.inotify.max_user_instances=1280 | sudo tee -a /etc/sysctl.conf
}

if ! command -v docker >/dev/null; then
    echo "Installing Docker"
    install_docker
fi
if ! command -v kind >/dev/null; then
    echo "Installing Kind"
    install_kind
fi
if ! command -v go >/dev/null; then
    echo "Installing go"
    install_go
fi
