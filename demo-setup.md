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



* `ssh ubuntu@IP -i ~/.ssh/nephio`
* `PARTICIPANT=the-participant-username`
* `./scripts/repos.sh create $PARTICIPANT` to create the GitHub repos
* Login to the participant VM
* Install [nephio-system](https://github.com/nephio-project/nephio-poc#installing-the-server-components)
  * John needs to update this with latest nephio-controller-poc,
    nephio-5gc-controller, and Wim's various IPAM and config injectors
  * That will add a bunch of CRDs, etc.
  * John also needs to build and push all the images to the registry
* Install [nephio-webui](https://github.com/nephio-project/nephio-poc#installing-the-web-ui)
  * Chris is fixing this so we don't need the OAuth stuff anymore, which will be
    much simpler.
* Install the [`participant`](https://github.com/nephio-project/one-summit-22-workshop/tree/main/packages/participant)package on the management cluster
* Install [ConfigSync](https://github.com/nephio-project/nephio-poc#installing-config-sync-in-workload-clusters) on the three workload clusters
  * Package and instructions probably need updating


## some commands
`ssh -L 7007:localhost:7007 -i ~/.ssh/nephio ubuntu@34.121.77.67`
`kubectl --kubeconfig ~/.kube/nephio.config port-forward --namespace=nephio-webui svc/nephio-webui 7007`

On your workstation browse to http://localhost:7007
