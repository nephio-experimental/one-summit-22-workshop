# kind-cluster-ansible
This is the ansible playbook for,
1. Installing kind, docker etc on the GCP VM.
2. Create multiple kind clusters on the GCP VM.
3. Install multus and weave CNIs on the kind clusters.


## todo

- This ansible should be triggered from the kind-cluster-gke terraform plan. So that we have one command to create the Infra.


## Requirements
- [ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#pip-install)

## Prerequisites
- Terraform plan executed already.
- External IP address of the GCP VM.
- ssh key for loging in to the VM. FIXME I am using the the key called google_compute_engine which is getting created after I execute "gcloud compute ssh --zone "us-central1-a" "nephio-poc-001"  --project "pure-faculty-367518"

## usage
Update the hosts.yaml with IP address of the VM, and the ssh private_key.
In the kind_setup.yaml set number of kind clusters to be created.

bash /home/ubuntu/multiclusterkind/kind_create_clusters.sh <number of kind clusters>.

```bash
ansible -i hosts.yaml all -m ping

ansible-playbook -i hosts.yaml kind_setup.yaml

PLAY [all] *******************************************************************************************

TASK [Gathering Facts] *******************************************************************************
ok: [server1]

TASK [Copy multuclusterkind directory] ***************************************************************
changed: [server1]

TASK [Prepare VM for kind installation] **************************************************************
changed: [server1]

TASK [Install kind clusters] *************************************************************************
changed: [server1]

PLAY RECAP *******************************************************************************************
server1                    : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

## Access the kind clusters
The kubeconfig files are present in the ~/.kube/cluster<n>.config files.
