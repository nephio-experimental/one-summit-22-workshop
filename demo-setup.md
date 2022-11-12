# demo setup

VMs are provisioned via Terraform, and within that VM the clusters are setup
using Ansible and other scripts.

GitHub rate limits mean repository creation may fail during bulk VM creation.
If that happens, the VM creation will continue, and we can provision the
repositories separately.

* Login to the [workshop VM](https://console.cloud.google.com/compute/instancesDetail/zones/us-central1-a/instances/workshop?project=pure-faculty-367518&supportedpurview=project)
* Navigate to the common workshop admin directory, and verify you have the
  latest scripts.
  ```bash
  sudo su - workshop
  cd one-summit-22-workshop
  git pull --ff-only
  ```
* Adjust the number of VMs to create by editing `infra/compute_instances.tf`,
  setting the `num_vms` parameter ([more info](infra/README.md)), then execute terraform:
  ```bash
  cd infra
  terraform plan
  # you should see that new VMs will be created
  terraform apply
  ```
* The result will give you the name and IP of the new VMs. They are also
  available via `gcloud compute instances list`.


## TODO (automation):
* `./scripts/repos.sh create $PARTICIPANT` to create the GitHub repos
* Install [ConfigSync](https://github.com/nephio-project/nephio-poc#installing-config-sync-in-workload-clusters) on the three workload clusters
  * Package and instructions probably need updating


## Some commands
* In these commands, `$IP` is the public IP address of the workshop VM.
* To use the UI, you need to forward ports from your workstation to the VM, and
  from the VM to the Pod.
  ```bash
  # login from your workstation, forwarding 7007 -> localhost:7007 on the remote VM.
  ssh -L7007:localhost:7007 -i ~/.ssh/nephio ubuntu@$IP
  # now you are in the remote VM, in there run
  kubectl --kubeconfig ~/.kube/nephio.config port-forward --namespace=nephio-webui svc/nephio-webui 7007
  ```
* On your workstation browse to [http://localhost:7007](http://localhost:7007)
* Create a second, separate login to the workshop VM for CLI access to the
  clusters:
  ```bash
  ssh -i ~/.ssh/nephio ubuntu@$IP
  ```
