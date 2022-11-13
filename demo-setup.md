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
* For any new VMs, you may need to create the GitHub repositories via
  `./scripts/repos.sh create $PARTICIPANT`


## Automation TODO

* The `repos.sh` script and GitHub token are available on the VM; we could run
`./repos.sh create $(hostname)` to automatically create the repositories. If we
do this, the script may fail due to repostories already existing, or due to GitHub
rate limits. So, we need to be sure it failing does not abort the rest of setup.
We also need to be prepared to run the script again from the workshop VM to
provision any repositories that failed to be created.
