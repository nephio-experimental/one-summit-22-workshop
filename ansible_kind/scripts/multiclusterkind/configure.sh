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
KPT_VERSION=1.0.0-beta.23

function _create_gh_secret {
    local nephio_gh_filename=$1

    if [ -f "$nephio_gh_filename" ]; then
        for kubeconfig in ~/.kube/*.config; do
            kubectl create secret generic -n default \
                github-personal-access-token \
                --from-literal username=nephio-test \
                --from-file password="${nephio_gh_filename}" \
                --type kubernetes.io/basic-auth \
                --kubeconfig "$kubeconfig"
        done
    fi
    rm -rf "${nephio_gh_filename}"
}

function _get_pkg {
    local pkg="$1"
    local path="$base_path/$pkg"
    url="https://github.com/nephio-project/nephio-packages.git/nephio-$pkg"

    if ! [ -d "$path" ]; then
        sudo -E kpt pkg get --for-deployment "$url" "$path"
        sudo chown -R "$USER": "$path"
    fi
    if [[ ${DEBUG:-false} == "true" ]]; then
        kpt pkg tree "$path"
    fi
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
