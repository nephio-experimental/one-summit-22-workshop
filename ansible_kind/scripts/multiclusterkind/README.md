

## This script
- Creates kind clusters
- Installs the following in the clusters
    - Metallb
    - Multus
    - Macvlan
***
### Prerequisites
- ubuntu 20.04
- go 1.17.5+
- docker
- kubectl command
#####  
### Setup 
On a ubuntu 20.04 machine
- Run k8s_cluster_setup.sh, this will install all prerequisites to run the kind_create_cluster.sh
- Run the kind_create_cluster.sh script. It takes number of clusters as parameters, default is 4 
 
Example:  ./kind_create_clusters.sh 2


    Following gets installed in each cluster,
    export KUBECONFIG=~/.kube/cluster2.config
    kubectl  get pods -A
    NAMESPACE            NAME                                             READY   STATUS    RESTARTS   AGE
    kube-system          coredns-558bd4d5db-89ng8                         1/1     Running   0          49m
    kube-system          coredns-558bd4d5db-xd6hn                         1/1     Running   0          49m
    kube-system          etcd-cluster2-control-plane                      1/1     Running   0          49m
    kube-system          kindnet-4gt6v                                    1/1     Running   0          49m
    kube-system          kube-apiserver-cluster2-control-plane            1/1     Running   0          49m
    kube-system          kube-controller-manager-cluster2-control-plane   1/1     Running   0          49m
    kube-system          kube-multus-ds-v8qgc                             1/1     Running   0          48m
    kube-system          kube-proxy-lxcv5                                 1/1     Running   0          49m
    kube-system          kube-scheduler-cluster2-control-plane            1/1     Running   0          49m
    local-path-storage   local-path-provisioner-85494db59d-z4vjv          1/1     Running   0          49m
    metallb-system       controller-66445f859d-whkhn                      1/1     Running   0          49m
    metallb-system       speaker-2xvgq                                    1/1     Running   0          48m

 
## 
***
