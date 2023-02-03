FROM us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss@sha256:95d41b3669e98ddcde8b39384197b585536814cc4f1485a27c51dbf8ef487afd

ENV DEBIAN_FRONTEND=noninteractive

# Workaround: rm -rf /etc/apt/sources.list.d/yarn.list -> https://github.com/yarnpkg/yarn/issues/8918
RUN rm -rf /etc/apt/sources.list.d/yarn.list && \
    apt-get update && \
    apt-get install --no-install-recommends -y python3=3.9.2-3 python3-docker=4.1.0-1.2 && \
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
