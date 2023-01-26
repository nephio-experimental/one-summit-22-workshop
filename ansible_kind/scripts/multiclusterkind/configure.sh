#!/bin/bash
# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c) 2022
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

set -o pipefail
set -o errexit
set -o nounset
if [[ ${DEBUG:-false} == "true" ]]; then
    set -o xtrace
fi

nephio_gh_filename=${1:-$HOME/nephio-test-github-pat.txt}
base_path=/opt/nephio
system_path="$base_path/system"
webui_path="$base_path/webui"
participant=$(hostname)
participant_path="$base_path/$participant"
KPT_VERSION=1.0.0-beta.23

function _create_gh_secret {
    local nephio_gh_filename=$1

    if [ -f "$nephio_gh_filename" ]; then
        for kubeconfig in ~/.kube/*.config; do
            if [ ! kubectl get secrets github-personal-access-token -n default --kubeconfig "$kubeconfig" ]; then
                /home/ubuntu/.local/bin/kubectl create secret generic -n default \
                    github-personal-access-token \
                    --from-literal username=nephio-test \
                    --from-file password="${nephio_gh_filename}" \
                    --type kubernetes.io/basic-auth \
                    --kubeconfig "$kubeconfig"
            fi
        done
    fi
    rm -rf "${nephio_gh_filename}"
}

function _get_pkg {
    local pkg="$1"
    local url=${2:-"https://github.com/nephio-project/nephio-packages.git/nephio-$pkg"}
    local path="$base_path/$pkg"

    if ! [ -d "$path" ]; then
        sudo -E kpt pkg get --for-deployment "$url" "$path"
        sudo chown -R "$USER": "$path"
    fi
    if [[ ${DEBUG:-false} == "true" ]]; then
        kpt pkg tree "$path"
    fi
}

function _install_configsync {
    local kubeconfig="$1"
    local cluster
    cluster="$(hostname)-$(basename "$kubeconfig" ".config")"

    local path="$base_path/$cluster"
    _get_pkg "$cluster" https://github.com/nephio-project/nephio-packages.git/nephio-configsync

    kpt fn render "$path"
    kpt live init "$path" --force --kubeconfig "$kubeconfig"
    kpt live apply "$path" --reconcile-timeout=15m --kubeconfig "$kubeconfig"
}

if ! command -v kpt; then
    curl -s "https://i.jpillora.com/GoogleContainerTools/kpt@v$KPT_VERSION!" | bash
    kpt completion bash | sudo tee /etc/bash_completion.d/kpt >/dev/null
fi

sudo mkdir -p "$base_path"

_create_gh_secret "$nephio_gh_filename"

# Install server components
_get_pkg system
kpt fn render "$system_path"
kpt live init "$system_path" --force --kubeconfig ~/.kube/nephio.config
kpt live apply "$system_path" --reconcile-timeout=15m --kubeconfig ~/.kube/nephio.config

_get_pkg webui
kpt fn render "$webui_path"
kpt live init "$webui_path" --force --kubeconfig ~/.kube/nephio.config
kpt live apply "$webui_path" --reconcile-timeout=15m --kubeconfig ~/.kube/nephio.config

_get_pkg "$participant" "https://github.com/nephio-project/one-summit-22-workshop.git/packages/participant"
kpt fn render "$participant_path"
kpt live init "$participant_path" --force --kubeconfig ~/.kube/nephio.config
kpt live apply "$participant_path" --reconcile-timeout=15m --kubeconfig ~/.kube/nephio.config

# Install ConfigSync on each workload cluster
for kubeconfig in ~/.kube/*.config; do
    if [[ $kubeconfig =~ nephio.config$ ]]; then
        continue
    fi
    _install_configsync "$kubeconfig"
done

touch /home/ubuntu/.done
