Currently here are all the steps needed (that I know of) to fully provision a participant VM. Let's try to make this as automatic as possible. I think we should be able to create an overall script that does most of this - in fact, I know some of these are already tied together in an overall script, but I wanted to list out the main steps I could think of.

@joaofeteira I think this is what you were referring to on the call this morning, that we need this overall script.

* Login to the [workshop VM](https://console.cloud.google.com/compute/instancesDetail/zones/us-central1-a/instances/workshop?project=pure-faculty-367518&supportedpurview=project)
* `sudo su - workshop`
* `cd one-summit-22-workshop`
* `PARTICPANT=the-participant-username`
* `./scripts/repos.sh create $PARTICIPANT` to create the GitHub repos
* Run the VM creation script to create the participant VM ([see terraform section towards bottom of page](./infra/README.md) )
* Copy the `nephio-test-github-pat.txt` from the workshop VM to the participant VM
* Login to the participant VM
* Run the cluster creation and networking setup scripts
* Create the secret *in each cluster*:
  `kubectl create secret generic -ndefault github-personal-access-token --from-literal username=nephio-test --from-file password=~/nephio-test-github-pat.txt --type kubernetes.io/basic-auth`
* Delete the `nephio-test-github-pat.txt` (it's not critical but may as well)
* Install nephio-system: https://github.com/nephio-project/nephio-poc#installing-the-server-components
  * John needs to update this with latest nephio-controller-poc,
    nephio-5gc-controller, and Wim's various IPAM and config injectors
  * That will add a bunch of CRDs, etc.
  * John also needs to build and push all the images to the registry
* Install nephio-webui: https://github.com/nephio-project/nephio-poc#installing-the-web-ui
  * Chris is fixing this so we don't need the OAuth stuff anymore, which will be
    much simpler.
* Install the `participant` package on the management cluster: https://github.com/nephio-project/one-summit-22-workshop/tree/main/packages/participant
* Install ConfigSync on the three workload clusters: https://github.com/nephio-project/nephio-poc#installing-config-sync-in-workload-clusters
  * Package and instructions probably need updating

