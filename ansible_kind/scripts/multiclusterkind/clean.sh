#!/bin/bash
# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c) 2022
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

#
# GH_TOKEN is set or ~/nephio-test-github-pat.txt exists.
#
set -o pipefail
set -o errexit
set -o nounset
DEBUG=${DEBUG:-false}
if [[ $DEBUG == "true" ]]; then
    set -o xtrace
fi

function usage {
    printf "usage: %s [ --force ]\n" "$0"
    exit 1
}

if [[ $# -gt 1 ]]; then
    usage
fi

if [[ $# -eq 0 ]]; then
  echo "This script will reset the environment, cleaning up: "
  echo "  - All FiveGCoreTopology resources"
  echo "  - All PackageDeployment resources"
  echo "  - All PackageRevisions in the catalog, regional, and edge clusters"
  echo
  echo "Run the script with --force to execute it; there will be no confirmation prompt."
  exit 0
fi

# Remove the topology resource
echo kubectl --kubeconfig ~/.kube/nephio.config delete fivegcoretopologies --all
kubectl --kubeconfig ~/.kube/nephio.config delete fivegcoretopologies --all

# The PackageDeployment it generated should be gone (garbage collected) 
echo kubectl --kubeconfig ~/.kube/nephio.config get packagedeployments
kubectl --kubeconfig ~/.kube/nephio.config get packagedeployments

# But clean up any others we created
echo kubectl --kubeconfig ~/.kube/nephio.config delete packagedeployments --all
kubectl --kubeconfig ~/.kube/nephio.config delete packagedeployments --all



repos=(catalog regional edge-1 edge-2)

for p in "$@"; do
    echo "$p"
    for r in "${repos[@]}"; do
# PackageRevisions are NOT deleted (TODO item), so we need to do that 
        echo kpt alpha rpkg --kubeconfig ~/.kube/nephio.config del -n default \$\(kubectl --kubeconfig ~/.kube/nephio.config get packagerevision --output jsonpath="{.items[?(.spec.repository == '$r')].metadata.name}"\)
        kpt alpha rpkg --kubeconfig ~/.kube/nephio.config del -n default "$(kubectl --kubeconfig ~/.kube/nephio.config get packagerevision --output jsonpath="{.items[?(.spec.repository == '$r')].metadata.name}")"
    done
done
