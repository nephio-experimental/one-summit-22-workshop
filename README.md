# one-summit-22-workshop

This repository contains the scripts and other materials needed to execute the
workshop for SIG Automation at the 2022 ONE Summit in Seattle.

## Setup Details

### Overview
![overview](nephio-workshop.svg)

### Virtual Machine Details

| <!-- -->         | <!-- -->       |
|------------------|----------------|
| Operating System | Ubuntu 20.04.5 |
| Architecture     | x86_64         |
| Cores            | 8              |
| RAM              | 32 GB          |
| Disk             | 100 GB         |



### Pre-Installed Software
- docker 20.10.12
- git 2.25.1
- kubectl 1.25.4
- kpt

### KIND Clusters
KIND Version -> 0.11.1
Kubernetes Version -> v1.21.1

| Name     | Description | Control Nodes | Worker Nodes | CNIs | Operators |
|----------|-------------|---------------|--------------|------|-----------|
| nephio   |             |               |              |      |           |
| regional |             |               |              |      |           |
| edge-1   |             |               |              |      |           |
| edge-2   |             |               |              |      |           |

