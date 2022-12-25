#!/bin/bash
export USER=user
export BASE=$(pwd)
export LC_ALL=C.UTF-8
echo "-----------------"
echo "Change to install directory"
cd /nephio-ansible-install
echo "-----------------"
echo "Setting up python"
python3 -m venv .venv
source .venv/bin/activate
pip3 install --upgrade pip
pip3 install ansible
pip3 install kubernetes
pip3 install pygithub
pip3 install requests
ansible-galaxy collection install community.general
ansible-galaxy collection install kubernetes.core
ansible-galaxy collection install community.docker # required for gitea
echo "-----------------"
echo "Installing prereq..."
ansible-playbook --connection=local playbooks/install-prereq.yaml > 00_prereq.out 2>&1
echo "-----------------"
echo "Deploying gitea..."
ansible-playbook --connection=local playbooks/create-gitea.yaml > 01_gitea.out 2>&1
echo "-----------------"
echo "Creating repos..."
ansible-playbook --connection=local playbooks/create-gitea-repos.yaml > 02_repos.out 2>&1
echo "-----------------"
echo "Deploying clusters..."
ansible-playbook --connection=local playbooks/deploy-clusters.yaml > 03_clusters.out 2>&1
echo "-----------------"
echo "Configuring nephio..."
ansible-playbook --connection=local playbooks/configure-nephio.yaml > 04_nephio.out 2>&1
echo "-----------------"
echo "nephio demo installation done"
cd $BASE
echo "-----------------"
