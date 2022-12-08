# ansible nephio

## installation

This repo provides the artifacts to install a Nephio environment using ansible to experiment with Nephio following [nephio ONE summit 2022 workshop](https://github.com/nephio-project/one-summit-22-workshop). The installation creates kind clusters, github repos and the manifests to get a base Nephio environment up an running.

The installation assumes a VM is created with the following characteristics:

- ubuntu 22.04LTS -> this is tested right now
- 32G RAM, 8 vcpu -> we can change this based on the amount of kind clusters we need
- SSH access with a SSH key is setup + username

The creation of the VM is right now out of scope, but we can see what we can do going forward.
Also we assume right now the ansible playbook is executed remote from the VM. We can see if people want to use a different approach going forward.

In a local environment clone the repo in a local environment

```bash
git clone https://github.com/henderiw-nephio/nephio-ansible-install
cd nephio-ansible-install
```

The installation requires an inventory file that is tailored to your enviornment. The ansible.config assumes the inventory file is located in inventory/nephio.yaml within the cloned environment. Create an inventory directory and the nephio.yaml file within the inventory directory

```bash
mkdir -p inventory
touch inventory/nephio.yaml
```

Open an editor of your choice and paste the below in the inventory/nephio.yaml file.

--> You can choose between github repos (remote) or gitea repos (local) by setting the respective vars in the inventory/nephio.yaml file (see below).

```yaml
all:
  vars:
    cloud_user: <username that is used to access the VM>
    github_username: <github username>
    github_token: <github personal access token>
    github_organization: <github organization or username>
    gitea_username: <gitea username>
    gitea_password: <gitea password>
    proxy:
      http_proxy: 
      https_proxy:
      no_proxy:
    host_os: "linux"  # use "darwin" for MacOS X, "windows" for Windows
    host_arch: "amd64"  # other possible values: "386","arm64","arm","ppc64le","s390x"
    tmp_directory: "/tmp"
    bin_directory: "/usr/local/bin"
    kubectl_version: "1.25.0"
    kubectl_checksum_binary: "sha512:fac91d79079672954b9ae9f80b9845fbf373e1c4d3663a84cc1538f89bf70cb85faee1bcd01b6263449f4a2995e7117e1c85ed8e5f137732650e8635b4ecee09"
    kind_version: "0.17.0"
    cni_version: "0.8.6"
    kpt_version: "1.0.0-beta.23"
    multus_cni_version: "3.9.2"
    nephio:
      install_dir: nephio-install
      packages_url: https://github.com/nephio-project/nephio-packages.git
    clusters:
      mgmt: {mgmt_subnet: 172.88.0.0/16, pod_subnet: 10.196.0.0/16, svc_subnet: 10.96.0.0/16}
      edge1: {mgmt_subnet: 172.89.0.0/16, pod_subnet: 10.197.0.0/16, svc_subnet: 10.97.0.0/16}
      edge2: {mgmt_subnet: 172.90.0.0/16, pod_subnet: 10.198.0.0/16, svc_subnet: 10.98.0.0/16}
      region1: {mgmt_subnet: 172.91.0.0/16, pod_subnet: 10.199.0.0/16, svc_subnet: 10.99.0.0/16}
  children:
    vm:
      hosts:
        <ip address of the VM>:
```

Some customizations are required to tailor the installation to your environment. Edit the inventory/nephio.yaml file where you update:

- cloud_user: the username that is created to access the VM using SSH
- github_username: your github user name
- github_token: github access token to access github [github personal access token](https://docs.github.com/en/enterprise-server@3.4/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
- github_organization: (optional) if you use a github organization for the repo's you should add your github organization here, otherwise it uses the github username
- gitea_username: your [gitea](https://gitea.io) (local repo) username
- gitea_password: your [gitea](https://gitea.io) (local repo) password

Note: You can choose between using remote github repos or local gitea repos for your Nephio environment by setting either the github variables or the gitea variables.

To start running ansible playbooks an ansible environment is required. Below is an example how to install ansible using a virtual environment. The repo scripts rely on the ansible galaxy community collection

```python
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install ansible
pip install pygithub
ansible-galaxy collection install community.general
```

## deploy nephio environment

Now that the environment is up an running we can install the Nephio environment

First we create some prerequisites, which installs kubectl, kind, kpt, cni and setup the bash environment

```bash
ansible-playbook playbooks/install-prereq.yaml
```

Create the github repo(s) Nephio uses (optional: either choose to run this step for github or steps for gitea below)

```bash
ansible-playbook playbooks/create-repos.yaml
```

Create the gitea instance Nephio uses (optional: either choose to run this step for gitea or step for github above)

```bash
ansible-playbook playbooks/create-gitea.yaml
```

Create the gitea repo(s) Nephio uses (optional: either choose to run this step for gitea or step for github above)

```bash
ansible-playbook playbooks/create-gitea-repos.yaml
```

Next we deploy the kind clusters and install the nephio components

```bash
ansible-playbook playbooks/deploy-clusters.yaml
```

Lastly we install the environment manifests we use for the workshop scenario's

```bash
ansible-playbook playbooks/configure-nephio.yaml
```

## Accessing Your Environment

```bash
# login from your workstation
#   nephio webui: forwarding 7007 -> localhost:7007 on the remote VM.
#   gitea webui: forwarding 3000 -> localhost:3000 on the remote VM.
ssh -L7007:localhost:7007 -L3000:localhost:3000 [YOUR_CLOUD_USER]@$IP
# now you are in the remote VM, in there run
kubectl --kubeconfig ~/.kube/mgmt-config port-forward --namespace=nephio-webui svc/nephio-webui 7007
```

On your workstation you can now browse 
* to the URL [http://localhost:7007](http://localhost:7007) for the nephio webui
* to the URL [http://localhost:3000](http://localhost:3000) for the gitea webui (in case you chose to enable it by setting gitea username/password in inventory)

## destroy nephio environment

To destroy the nephio environment

```bash
ansible-playbook playbooks/destroy-clusters.yaml
```
