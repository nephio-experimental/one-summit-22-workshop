FROM us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && \
    apt install -y python3 python3-docker && \
    rm -rf /var/lib/apt/lists/*

RUN wget -q https://open-vsx.org/api/redhat/vscode-yaml/1.10.1/file/redhat.vscode-yaml-1.10.1.vsix && \
unzip redhat.vscode-yaml-1.10.1.vsix "extension/*" && \
mv extension /opt/code-oss/extensions/redhat.vscode-yaml

RUN wget -q https://open-vsx.org/api/ms-kubernetes-tools/vscode-kubernetes-tools/1.3.11/file/ms-kubernetes-tools.vscode-kubernetes-tools-1.3.11.vsix && \
unzip ms-kubernetes-tools.vscode-kubernetes-tools-1.3.11.vsix "extension/*" && \
mv extension /opt/code-oss/extensions/ms.kubernetes-tools

RUN mkdir -p /nephio-installation/inventory
COPY ansible.cfg /nephio-installation/
COPY playbooks /nephio-installation/playbooks
COPY roles /nephio-installation/roles
COPY nind/nephio.yaml /nephio-installation/inventory/
COPY nind/150_install-nephio.sh /etc/workstation-startup.d/
