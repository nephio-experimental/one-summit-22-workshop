FROM us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && \
    apt install -y python3 python3-docker && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /nephio-ansible-install/inventory
COPY ansible.cfg /nephio-ansible-install/
COPY playbooks /nephio-ansible-install/playbooks
COPY roles /nephio-ansible-install/roles
COPY demo-container/nephio.yaml /nephio-ansible-install/inventory/
COPY demo-container/150_install-nephio.sh /etc/workstation-startup.d/
