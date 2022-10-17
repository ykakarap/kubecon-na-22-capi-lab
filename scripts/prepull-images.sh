#!/usr/bin/env bash

# Bootstrap cluster:
docker pull kindest/node:v1.24.6
docker pull kindest/node:v1.25.2
docker pull kindest/haproxy:v20210715-a6da3463

# Mgmt cluster:
## Cluster API
docker pull gcr.io/k8s-staging-cluster-api/capd-manager:v1.2.4
docker pull k8s.gcr.io/cluster-api/cluster-api-controller:v1.2.4
docker pull k8s.gcr.io/cluster-api/kubeadm-bootstrap-controller:v1.2.4
docker pull k8s.gcr.io/cluster-api/kubeadm-control-plane-controller:v1.2.4
## cert-manager
docker pull quay.io/jetstack/cert-manager-cainjector:v1.9.1
docker pull quay.io/jetstack/cert-manager-controller:v1.9.1
docker pull quay.io/jetstack/cert-manager-webhook:v1.9.1

# Workload
docker pull k8s.gcr.io/pause:3.7
docker pull docker.io/calico/cni:v3.24.1
docker pull docker.io/calico/kube-controllers:v3.24.1
docker pull docker.io/calico/node:v3.24.1

# Cluster API visualizer
docker pull ghcr.io/jont828/cluster-api-visualizer:v1.0.0
