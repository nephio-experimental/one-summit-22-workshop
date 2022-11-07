# kind-cluster-gce

Terraform code to provision Kind clusters on top of GCE Instances.
For now it creates a number (that can be defined) of Kind K8S Clusters (based on the scripts folder) for central and edge clusters.
We can even set multiple interfaces for each VM in order to have additional NICs for Multus for instance.

## todo

- automate the #Post section of the scripts

## requirements

- [terraform 1.3.2](https://www.terraform.io/downloads.html)
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)

## usage

To run the terraform code locally change the variable project_id in general.auto.tfvars and:

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project PROJECT_ID
terraform init
terraform plan
terraform apply
```

To access the VM after creation:

```bash
gcloud compute ssh --zone ZONE VM_NAME --project "XXXX" --tunnel-through-iap
```

(one can get the VM name from the terraform outputs or via gcloud compute instances list)
