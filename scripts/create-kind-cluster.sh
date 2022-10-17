#!/usr/bin/env bash

kind create cluster --config ./yamls/bootstrap/kind.yaml -n kubecon-na-22-capi-lab

echo "Load pre-downloaded images into kind cluster"

# Load CAPI
kind -n kubecon-na-22-capi-lab load docker-image gcr.io/k8s-staging-cluster-api/capd-manager:v1.2.4 k8s.gcr.io/cluster-api/cluster-api-controller:v1.2.4 k8s.gcr.io/cluster-api/kubeadm-bootstrap-controller:v1.2.4 k8s.gcr.io/cluster-api/kubeadm-control-plane-controller:v1.2.4

# Load cert-manager
kind -n kubecon-na-22-capi-lab load docker-image quay.io/jetstack/cert-manager-cainjector:v1.9.1 quay.io/jetstack/cert-manager-controller:v1.9.1 quay.io/jetstack/cert-manager-webhook:v1.9.1

# Load Cluster API visualizer
kind -n kubecon-na-22-capi-lab load docker-image ghcr.io/jont828/cluster-api-visualizer:v1.0.0
