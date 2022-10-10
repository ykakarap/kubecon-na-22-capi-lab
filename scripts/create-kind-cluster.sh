#!/usr/bin/env bash

kind create cluster --config ./yamls/bootstrap/kind.yaml

echo "Load pre-downloaded images into kind cluster"

# Load CAPI
kind load docker-image gcr.io/k8s-staging-cluster-api/capd-manager:v1.2.3 k8s.gcr.io/cluster-api/cluster-api-controller:v1.2.3 k8s.gcr.io/cluster-api/kubeadm-bootstrap-controller:v1.2.3 k8s.gcr.io/cluster-api/kubeadm-control-plane-controller:v1.2.3

# Load cert-manager
kind load docker-image quay.io/jetstack/cert-manager-cainjector:v1.9.1 quay.io/jetstack/cert-manager-controller:v1.9.1 quay.io/jetstack/cert-manager-webhook:v1.9.1
