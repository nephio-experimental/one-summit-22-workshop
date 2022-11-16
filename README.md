# ONE Summit 2022 Nephio Workshop

Welcome! Each participant has been provisioned a VM with a complete
simulated multi-cluster environment with the Nephio proof-of-concept code
already pre-installed, as described in our [participant VM](participant-vm.md)
page.  Please take a look at that page to get an understanding of the
environment.

The organizers will provide you with an IP address for your VM and the ssh
private key that can be used to login to the machine. You will need an ssh
client capable of port forwarding and a browser to participate in the workshop.

For the workshop exercises, you will be using both the prototype Web UI and
various `kubectl` commands run on your participant VM. To access your environment,
you will start an ssh session that will all your local laptop to access the Web
UI running in the Nephio cluster on the VM.

In all the commands below, `$IP` is the public IP address of your workshop
participant VM.

To use the UI, you need to forward ports from your workstation to the VM, and
from the VM to the Pod. The instructions below work on Linux and Mac; you will
need to consult the docs of your ssh client if you are using a Windows
machine.

```bash
# login from your workstation, forwarding 7007 -> localhost:7007 on the remote VM.
ssh -L7007:localhost:7007 -i ~/.ssh/nephio ubuntu@$IP
# now you are in the remote VM, in there run
kubectl --kubeconfig ~/.kube/nephio.config port-forward --namespace=nephio-webui svc/nephio-webui 7007
```
On your workstation you can now browse to the URL
[http://localhost:7007](http://localhost:7007), and you should see something
like the image below.

![WebUI Landing Page](nephio-ui-landing.png)

You will need to leave the port forwarding up and running in that ssh session.
So, for `kubectl` access, you need to start a second ssh session, this time
without any port forwarding. This will be used for all the CLI access to the
clusters running on the participant VM. Create a new terminal window or tab on
your laptop and run:

```bash
ssh -i ~/.ssh/nephio ubuntu@$IP
```

You can then check if you our cluster is working with `kubectl`:

```bash
ubuntu@nephio-poc-001:~$ kubectl --kubeconfig ~/.kube/nephio.config -n nephio-system get pods
NAME                                                        READY   STATUS    RESTARTS   AGE
ipam-controller-65fb5fc8d4-5m8ts                            2/2     Running   0          24m
nephio-5gc-controller-594cfd86b8-c9vbf                      2/2     Running   0          24m
nf-injector-controller-66f885d554-b6pqq                     2/2     Running   0          24m
package-deployment-controller-controller-785688cb75-nnbvt   2/2     Running   0          24m
ubuntu@nephio-poc-001:~$
```

## Some Concepts and Terminology

A *Custom Resource Definition* or *CRD* is a Kubernetes extension mechanism for
adding custom data types to Kubernetes. The CRDs are the schemas - analogous to
table definitions in a relational database for example. The instances of those -
analogous to rows in a RDBMS - are called *Custom Resources* or *CRs*. People
often accidentally say "CRDs" when they mean "CRs", so be sure to ask for
clarification if the context doesn't make it clear which is meant.

In Kubernetes, resources - built-in ones as well as CRs - are processed by
*controllers*. A controller *actuates* the resource. For example, K8s
actuates a Service with Type LoadBalancer by creating a cloud provider
load balancer instance. Since Kubernetes is
*declarative*, it doesn't just actuate once. Instead, it actively reconciles
the intent declared in the resource, with the actual state of the managed
entity. If the state of the entity changes (a Pod is destroyed), Kubernetes will
modify or recreate the entity to match the desired state. And of course if the
intended state changes, Kubernetes will actuate the new intention. Speaking
precisely, a *controller* manages one or a few very closely related types of
resources. A *controller manager* is single binary that embeds multiple
controllers, and an *operator* is a set of these that manages a particular type
of workload. Speaking loosely, *controller* and *operator* are often used
interchangeably, though an *operator* always refers to code managing CRs rather
than Kuberenetes built-in types.

*Packages* or *Kpt Packages* are bundles of Kubernetes resource files, along
with a Kptfile (also in Kubernetes Resource Model or KRM format). They provide
the basic unit of management in the Kpt toolchain. This toolchain is used to
manage the configuration before it reaches the Kubernetes API server. This
"shift left" model is critical to allowing **safe** collaborative, automated
configuration creation and editing, because errors or partial configurations can
be resolved prior to affecting operations.

A package may have a single *upstream* parent, and many *downstream*
descendants. The Kptfiles in these packages are used to maintain the
relationships, capturing ancestry relationships like those shown below.

![Package Ancestry](package-ancestry.png)

By tracking these relationships, changes at the original source can be
propagated via controlled automation down the tree.

## Package Lifecycle

![Package Lifecycle](package-lifecycle.png)

## Things To Try

**Work In Progress Section**

### Create an Organizational Version of the free5gc Operator Package
Part of the idea of Nephio is to help manage the relationship between vendor,
organizational, team, and individual deployment variants of each package.

Let's create our own organizational variant of the upstream free5gc package,
using the Web UI.

From the **Dashboard**, choose the *catalog* link under **Organizational
Blueprints**. This represents the private catalog of packages that have been
customized for your organization. In the resulting screen, push the **ADD
ORGANIZATIONAL BLUEPRINT** button.

...results in free5gc-operator package in the `catalog` repository...

### Deploy the free5gc Operator
We can use a `PackageDeployment` resource to create a multi-cluster deployment
across all edge clusters of our customized `free5gc-operator` package.

We have UI screen to do this.

This YAML tells the package deployment controller to create package revisions in
each of the repositories for the edge clusters, based on our version of the
operator package (note the `repository` is `catalog` not `free5gc-packages`):

```yaml
apiVersion: automation.nephio.org/v1alpha1
kind: PackageDeployment
metadata:
  name: free5gc-operator-edge
  namespace: default
spec:
  name: free5gc-operator
  namespace: free5gc
  packageRef:
    packageName: free5gc-operator
    repository: catalog
    revision: v1
  selector:
    matchLabels:
      nephio.org/region: us-central1
      nephio.org/site-type: edge
```

Save the YAML above in a file, `pd-free5gc-operator.yaml` on your participant
VM. Then, you can deploy it with:

```bash
kubectl --kubeconfig ~/.kube/nephio.config apply -f pd-free5gc-operator.yaml
```

After a few minutes, you should see the package in Draft form on each edge
cluster, as shown in the UI screenshot below.

**Screenshot WIP**

### Deploy a `FiveGCoreTopology`
```yaml
apiVersion: nf.nephio.org/v1alpha1
kind: FiveGCoreTopology
metadata:
  name: fivegcoretopology-sample
spec:
  upfs:
    - name: "agg-layer"
      selector:
        matchLabels:
          nephio.org/region: us-central1
          nephio.org/site-type: edge
      namespace: "upf"
      upf:
        upfClassName: "free5gc-upf"
        capacity:
          uplinkThroughput: "1G"
          downlinkThroughput: "10G"
        n3:
          - networkInstance: "sample-vpc"
            networkName: "sample-n3-net"
        n4:
          - networkInstance: "sample-vpc"
            networkName: "sample-n4-net"
        n6:
          - dnn: "internet"
            uePool:
              networkInstance: "sample-vpc"
              networkName: "ue-net"
              prefixSize: "16"
            endpoint:
              networkInstance: "sample-vpc"
              networkName: "sample-n6-net"
```

## What's Happening Under the Hood

![Prototype Flow](nephio-poc-nov.jpg)

## Troubleshooting and Utility Commands

This is all prototype code. It is not anywhere near production ready. As such,
it sometimes behaves badly. This section gives a few commands that are useful in
resetting your environment.


### Restarting Controllers

```bash

# Restart each controller
kubectl --kubeconfig ~/.kube/nephio.config -n nephio-system rollout restart deploy package-deployment-controller-controller
kubectl --kubeconfig ~/.kube/nephio.config -n nephio-system rollout restart deploy nephio-5gc-controller
kubectl --kubeconfig ~/.kube/nephio.config -n nephio-system rollout restart deploy ipam-controller
kubectl --kubeconfig ~/.kube/nephio.config -n nephio-system rollout restart deploy nf-injector-controller

# Check to see if the restart is done
kubectl --kubeconfig ~/.kube/nephio.config -n nephio-system get po
```

### Viewing Controller Logs

```bash
# PackageDeployment controller
kubectl --kubeconfig ~/.kube/nephio.config -n nephio-system logs -c controller -l app.kubernetes.io/name=package-deployment-controller

# FiveGCoreTopologyController
kubectl --kubeconfig ~/.kube/nephio.config -n nephio-system logs -c controller -l app.kubernetes.io/name=nephio-5gc

# NF Injector
kubectl --kubeconfig ~/.kube/nephio.config -n nephio-system logs -c controller -l app.kubernetes.io/name=nf-injector

# IPAM controller
kubectl --kubeconfig ~/.kube/nephio.config -n nephio-system logs -c controller -l app.kubernetes.io/name=ipam
```

### Restarting the Web UI

```bash

# Restart the deployment
kubectl --kubeconfig ~/.kube/nephio.config -n nephio-webui rollout restart deploy nephio-webui

# Check if the restart is complete

kubectl --kubeconfig ~/.kube/nephio.config -n nephio-webui get po
```

### Cleaning Up Everything

```bash

# Run the clean.sh to see what it will do
~/multiclusterkind/clean.sh

# make sure you really want to do what it says, then
~/multiclusterkind/clean.sh --force
```
