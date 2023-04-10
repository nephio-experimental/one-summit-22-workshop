#!/bin/bash
# shellcheck disable=SC1091
export USER=user
BASE=$(pwd)
export BASE
export LC_ALL=C.UTF-8
echo "Activating extensions..."
/opt/code-oss/bin/codeoss-cloudworkstations --install-extension redhat.vscode-yaml
/opt/code-oss/bin/codeoss-cloudworkstations --install-extension ms-kubernetes-tools.vscode-kubernetes-tools
echo "-----------------"
echo "-----------------"
echo "Change to install directory"
cd /nephio-installation || exit
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
echo "Setting kubeconfig..."
mkdir /home/user/.kube
for file in /root/.kube/*-config
do
  if [ -n "$KUBECONFIG" ]; then
    export KUBECONFIG=$KUBECONFIG:${file}
  else
    export KUBECONFIG=${file}
  fi
done
kubectl config view --flatten > /home/user/.kube/config
chown -R user:user /home/user/.kube
echo "-----------------"
cd "$BASE" || exit
echo "nephio-in-docker installation done"
echo "-----------------"
