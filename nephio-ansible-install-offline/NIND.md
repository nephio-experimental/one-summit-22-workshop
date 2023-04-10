# nephio-in-docker (nind)

## tldr

nephio-in-docker (nind) packages the nephio-ansible-install into a [Docker](https://docs.docker.com/get-docker/) container following the setup used in the [nephio ONE summit 2022 workshop](https://github.com/nephio-project/one-summit-22-workshop).
In addition nind also runs a [VS Code OSS](https://github.com/microsoft/vscode) workstation instance providing a browser based development and test enviroment.

To build and run nephio-in-docker execute the commands listed below:

```bash
git clone https://github.com/nephio-project/one-summit-22-workshop.git
cd one-summit-22-workshop/nephio-ansible-install
docker build -t nind .
docker run --name=nind --rm --env='DOCKER_OPTS=' --volume=/var/lib/docker --privileged \
  --cgroup-parent=nephio.slice --restart=no -d -p 8080:80 -p 7007:7007 -p 3000:3000 nind
```
Note that it will take about 10 mins for nephio to set up after starting the container as it executes the commands in the [installation script](/nephio-ansible-install/nind/150_install-nephio.sh).
You can follow the nephio installation progress by connecting to the nind container and access the installation log files.

```bash
# connect to the nind container 
docker exec -it nind bash

# change to the nephio installation directory
cd /nephio-installation

# you will see 5 log files coming up logging the progress of the installation steps.
# 00_prereq.out, 01_gitea.out, 02_repos.out, 03_clusters.out and 04_nephio.out
# when the last step starts executing follow the progress by tailing its log file.
tail -f 04_nephio.out

# once the installtion completes you will see a line like the one below.
PLAY RECAP *********************************************************************
localhost                  : ok=22   changed=18   unreachable=0    failed=0    skipped=9    rescued=0    ignored=0
```

You can build and run nind on any laptop or workstaton that packs-the-punch to let nephio fly.
Refer to the VM specs outlined in the nephio-ansible-install [README.md](/nephio-ansible-install/README.md#installation) of this repository.

In case you do not have a suitable laptop or workstation available you can also build and run the nind container on Google's [Cloud Workstations](https://cloud.google.com/workstations/docs/overview). The [online documentation](https://cloud.google.com/workstations/docs/customize-container-images#building_a_custom_container_image) outlines the instructions to do so.

## nephio webui
Now that the nephio environment is up an running you can connect to the nephio webui by pointing your browser to [http://localhost:7007](http://localhost:7007)

![nephio webui](/nephio-ansible-install/diagrams/nephio-webui.png "nephio webui")

## gitea repos
To access the gitea repos you can connect to [http://localhost:3000](http://localhost:3000) using nephio/nephio as the access credentials.

![gitea-repos](/nephio-ansible-install/diagrams/gitea-repos.png "gitea repos")

## workstation
The workstation can be accessed by connecting your browser to [http://localhost:8080](http://localhost:8080)

![workstation](/nephio-ansible-install/diagrams/workstation.png "workstation")
