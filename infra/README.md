# kind-cluster-gce

Terraform code to provision Kind clusters on top of GCE Instances

## requirements

- [terraform 1.3.2](https://www.terraform.io/downloads.html)
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

## usage

- Generate the SSH Key on your local machine:

```bash
ssh-keygen -t rsa -f ~/.ssh/nephio -C nephio -b 2048
```
- To run the terraform code locally run:

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project PROJECT_ID
terraform init
terraform plan
terraform apply
```

## VM Access

To access the VM after creation run:

```bash
ssh ubuntu@IP -i ~/.ssh/nephio
```
