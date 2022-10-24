# Prerequisites

## Minimum Resources
Please ensure you have at least: 4 CPU, 16 GB RAM and 32 GB free disk space.

**Warning**: Windows instructions are best effort and this tutorial may cause instability on some systems.

**
<!-- table of contents generated via: https://github.com/thlorenz/doctoc -->
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [Linux](#linux)
  - [Install Docker, kubectl, kind, clusterctl and helm](#install-docker-kubectl-kind-clusterctl-and-helm)
  - [Clone the tutorial repository](#clone-the-tutorial-repository)
  - [Pre-download container images](#pre-download-container-images)
  - [Verification](#verification)
- [macOS](#macos)
  - [Install Docker, kubectl, kind, clusterctl and helm](#install-docker-kubectl-kind-clusterctl-and-helm-1)
  - [Clone the tutorial repository](#clone-the-tutorial-repository-1)
  - [Pre-download container images](#pre-download-container-images-1)
  - [Verification](#verification-1)
- [Windows](#windows)
  - [Clone the tutorial repository](#clone-the-tutorial-repository-2)
  - [Put the tutorial repo on the $PATH](#put-the-tutorial-repo-on-the-path)
  - [Install Docker, kubectl, kind, clusterctl and helm](#install-docker-kubectl-kind-clusterctl-and-helm-2)
  - [Pre-download container images](#pre-download-container-images-2)
  - [Verification](#verification-2)
- [Avoid GitHub rate-limiting when running the tutorial without the local clusterctl repository](#avoid-github-rate-limiting-when-running-the-tutorial-without-the-local-clusterctl-repository)
- [Next: Creating Your First Cluster With Cluster API](#next-creating-your-first-cluster-with-cluster-api)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Linux
### Install Docker, kubectl, kind, clusterctl and helm

Install Docker as documented on the Docker website. You can choose between:
* [Docker Engine (e.g. Ubuntu)](https://docs.docker.com/engine/install/ubuntu/) (preferred)
* [Docker Desktop](https://docs.docker.com/desktop/install/linux-install/)

Verify the Docker installation via:
```bash
docker version
docker ps
```
**Note:** Fedora users should ensure to [correctly configure Docker](./troubleshooting.md#fedora-cluster-never-provisions) before continuing.
**Note**: If you are using Docker Desktop please ensure the Docker VM has at least 4 CPU, 10 GB RAM and 32 GB disk.
**Note**: You should ensure that [some system settings are correct before continuing](./troubleshooting.md#too-many-open-files)

Install kubectl as documented in [Install and Set Up kubectl on Linux](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/).

Verify kubectl via:
```bash
kubectl version --client -o yaml
```

At the time of this writing the above link will guide you to download a version 1.25 of the kubectl binary. [Based on the official Kubernetes version skew policy](https://kubernetes.io/releases/version-skew-policy/#kubectl) you will be able to use either 1.24, 1.25, or 1.26 of kubectl to follow the tutorial, which will have you create and upgrade Kubernetes clusters running versions 1.24 and 1.25.

Install kind v0.16.0 by downloading it from the [kind release page](https://github.com/kubernetes-sigs/kind/releases/tag/v0.16.0) and adding it to the path.

```bash
curl -L https://github.com/kubernetes-sigs/kind/releases/download/v0.16.0/kind-linux-amd64 -o /tmp/kind
sudo install -o root -g root -m 0755 /tmp/kind /usr/local/bin/kind

kind version
```

Install clusterctl v1.2.4 by downloading it from the [ClusterAPI release page](https://github.com/kubernetes-sigs/cluster-api/releases/tag/v1.2.4) and adding it to the path.

```bash
curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.2.4/clusterctl-linux-amd64 -o /tmp/clusterctl
sudo install -o root -g root -m 0755 /tmp/clusterctl /usr/local/bin/clusterctl

clusterctl version
```

Install helm v3.10.0 by downloading it from the [Helm release page](https://github.com/helm/helm/releases/tag/v3.10.0) and adding it to the path.

```bash
curl -L https://get.helm.sh/helm-v3.10.0-linux-amd64.tar.gz -o /tmp/helm.tar.gz
tar -zxvf /tmp/helm.tar.gz -C /tmp
sudo install -o root -g root -m 0755 /tmp/linux-amd64/helm /usr/local/bin/helm

helm version
```

### Clone the tutorial repository

```bash
git clone https://github.com/ykakarap/kubecon-na-22-capi-lab
cd kubecon-na-22-capi-lab

export CLUSTERCTL_REPOSITORY_PATH=$(pwd)/clusterctl/repository
```

**Notes**:
* The `CLUSTERCTL_REPOSITORY_PATH` environment variable is required later so we're able to run the tutorial offline.
* You can also download the repository via this link if you don't have `git` installed: [main.zip](https://github.com/ykakarap/kubecon-na-22-capi-lab/archive/refs/heads/main.zip).

### Pre-download container images

As we don't want to rely on the conference WiFi please pre-pull the container images used in the tutorial via:

```bash
sh ./scripts/prepull-images.sh
```

### Verification

This section describes steps to verify everything has been installed correctly.

Create the kind cluster: (including pre-loading images)
```bash
sh ./scripts/create-kind-cluster.sh
```

Should return:
```bash
Creating cluster "kubecon-na-22-capi-lab" ...
 ✓ Ensuring node image (kindest/node:v1.25.2) 🖼
 ✓ Preparing nodes 📦
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹️
 ✓ Installing CNI 🔌
 ✓ Installing StorageClass 💾
Set kubectl context to "kind-kubecon-na-22-capi-lab"
You can now use your cluster with:

kubectl cluster-info --context kind-kubecon-na-22-capi-lab

Thanks for using kind! 😊
Load pre-downloaded images into kind cluster
Image: "gcr.io/k8s-staging-cluster-api/capd-manager:v1.2.4" with ID "sha256:ce58906cdf5645b9a74274d85b56acc717c29be16019732fd7a647ad898dadc8" not yet present on node "kubecon-na-22-capi-lab-control-plane", loading...
Image: "k8s.gcr.io/cluster-api/cluster-api-controller:v1.2.4" with ID "sha256:59a7be1f86721c75bceb6d9a31f12846ae9c6984130301b943bb4bc90a9a8f95" not yet present on node "kubecon-na-22-capi-lab-control-plane", loading...
Image: "k8s.gcr.io/cluster-api/kubeadm-bootstrap-controller:v1.2.4" with ID "sha256:b0fa2436bbfa2e6c9f60175b82c0cb9d98e8d77c9659d9437d224cf25ec80000" not yet present on node "kubecon-na-22-capi-lab-control-plane", loading...
Image: "k8s.gcr.io/cluster-api/kubeadm-control-plane-controller:v1.2.4" with ID "sha256:bb531d56d11c3086b5b03db7e9e42f68b003fa39ad07d1ce6a8d22e669f8c23b" not yet present on node "kubecon-na-22-capi-lab-control-plane", loading...
Image: "quay.io/jetstack/cert-manager-cainjector:v1.9.1" with ID "sha256:11778d29f8cc283a72a84fbd68601a631fc7705fe2f12a70ea5df7ca3262dfe9" not yet present on node "kubecon-na-22-capi-lab-control-plane", loading...
Image: "quay.io/jetstack/cert-manager-controller:v1.9.1" with ID "sha256:8eaca4249b016e1e355957d357a39a0a8a837e1837054e8762fe7d1cd13051af" not yet present on node "kubecon-na-22-capi-lab-control-plane", loading...
Image: "quay.io/jetstack/cert-manager-webhook:v1.9.1" with ID "sha256:d3348bcdc1e7e39e655c3b17106fe2e2038cfd70d080a3ac89a9eaf3bd26fc3d" not yet present on node "kubecon-na-22-capi-lab-control-plane", loading...
Image: "gcr.io/kakaraparthy-devel/cluster-api-visualizer:v1.0.0" with ID "sha256:76f45f9fdeb341ab49094bc424dda68acb2c2e22f08b63c9b8855fe42b620f17" not yet present on node "kubecon-na-22-capi-lab-control-plane", loading...
Image: "gcr.io/kakaraparthy-devel/test-extension:v1.0.1" with ID "sha256:5f09148f8fbfcffea6738f07e60205b477dcec37df31e49ad8432886ec46f29d" not yet present on node "kubecon-na-22-capi-lab-control-plane", loading...
```

**Note** The following error can be ignored: `ERROR: failed to load image: command "docker exec --privileged ... already exists` as the image load works even if this error occurs.

Test kubectl:
```bash
kubectl get node
```

Should return:
```bash
NAME                                   STATUS   ROLES           AGE    VERSION
kubecon-na-22-capi-lab-control-plane   Ready    control-plane   3m5s   v1.25.2
```

Delete the kind cluster:
```bash
kind delete cluster --name=kubecon-na-22-capi-lab
```

Next: [Creating Your First Cluster With Cluster API](#next-creating-your-first-cluster-with-cluster-api)

## macOS

### Install Docker, kubectl, kind, clusterctl and helm

Install Docker Desktop as documented in [Install Docker Desktop on Mac](https://docs.docker.com/desktop/install/mac-install/).

Verify the Docker installation via:
```bash
docker version
docker ps
```

**Note**: Please ensure the Docker VM has at least 4 CPU, 10 GB RAM and 32 GB disk.

Install kubectl as documented in [Install and Set Up kubectl on macOS](https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/).

Verify kubectl via:
```bash
kubectl version --client -o yaml
```

At the time of this writing the above link will guide you to download a version 1.25 of the kubectl binary. [Based on the official Kubernetes version skew policy](https://kubernetes.io/releases/version-skew-policy/#kubectl) you will be able to use either 1.24, 1.25, or 1.26 of kubectl to follow the tutorial, which will have you create and upgrade Kubernetes clusters running versions 1.24 and 1.25.

Install kind v0.16.0 by downloading it from the [kind release page](https://github.com/kubernetes-sigs/kind/releases/tag/v0.16.0) and adding it to the path.

For amd64:
```bash
curl -L https://github.com/kubernetes-sigs/kind/releases/download/v0.16.0/kind-darwin-amd64 -o /tmp/kind
chmod +x /tmp/kind
sudo mv /tmp/kind /usr/local/bin/kind
sudo chown root: /usr/local/bin/kind

kind version
```

For arm64: (if your Mac has an M1 CPU (”Apple Silicon”))
```bash
curl -L https://github.com/kubernetes-sigs/kind/releases/download/v0.16.0/kind-darwin-arm64 -o /tmp/kind
chmod +x /tmp/kind
sudo mv /tmp/kind /usr/local/bin/kind
sudo chown root: /usr/local/bin/kind

kind version
```

Install clusterctl v1.2.4 by downloading it from the [ClusterAPI release page](https://github.com/kubernetes-sigs/cluster-api/releases/tag/v1.2.4) and adding it to the path.

For amd64:
```bash
curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.2.4/clusterctl-darwin-amd64 -o /tmp/clusterctl
chmod +x /tmp/clusterctl
sudo mv /tmp/clusterctl /usr/local/bin/clusterctl
sudo chown root: /usr/local/bin/clusterctl

clusterctl version
```

For arm64: (if your Mac has an M1 CPU (”Apple Silicon”))
```bash
curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.2.4/clusterctl-darwin-arm64 -o /tmp/clusterctl
chmod +x /tmp/clusterctl
sudo mv /tmp/clusterctl /usr/local/bin/clusterctl
sudo chown root: /usr/local/bin/clusterctl

clusterctl version
```

Install helm v3.10.0 by downloading it from the [Helm release page](https://github.com/helm/helm/releases/tag/v3.10.0) and adding it to the path.

For amd64:
```bash
curl -L https://get.helm.sh/helm-v3.10.0-darwin-amd64.tar.gz -o /tmp/helm.tar.gz
tar -zxvf /tmp/helm.tar.gz -C /tmp
chmod +x /tmp/darwin-amd64/helm
sudo mv /tmp/darwin-amd64/helm /usr/local/bin/helm
sudo chown root: /usr/local/bin/helm

helm version
```

For arm64: (if your Mac has an M1 CPU (”Apple Silicon”))
```bash
curl -L https://get.helm.sh/helm-v3.10.0-darwin-arm64.tar.gz -o /tmp/helm.tar.gz
tar -zxvf /tmp/helm.tar.gz -C /tmp
chmod +x /tmp/darwin-arm64/helm
sudo mv /tmp/darwin-arm64/helm /usr/local/bin/helm
sudo chown root: /usr/local/bin/helm

helm version
```

### Clone the tutorial repository

```bash
git clone https://github.com/ykakarap/kubecon-na-22-capi-lab
cd kubecon-na-22-capi-lab

export CLUSTERCTL_REPOSITORY_PATH=$(pwd)/clusterctl/repository
```

**Notes**:
* The `CLUSTERCTL_REPOSITORY_PATH` environment variable is required later so we're able to run the tutorial offline.
* You can also download the repository via this link if you don't have `git` installed: [main.zip](https://github.com/ykakarap/kubecon-na-22-capi-lab/archive/refs/heads/main.zip).

### Pre-download container images

As we don't want to rely on the conference WiFi please pre-pull the container images used in the tutorial via:

```bash
sh ./scripts/prepull-images.sh
```

### Verification

This section describes steps to verify everything has been installed correctly.

Create the kind cluster: (including pre-loading images)
```bash
sh ./scripts/create-kind-cluster.sh
```

Should return:
```bash
Creating cluster "kubecon-na-22-capi-lab" ...
 ✓ Ensuring node image (kindest/node:v1.25.2) 🖼
 ✓ Preparing nodes 📦
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹️
 ✓ Installing CNI 🔌
 ✓ Installing StorageClass 💾
Set kubectl context to "kind-kubecon-na-22-capi-lab"
You can now use your cluster with:

kubectl cluster-info --context kind-kubecon-na-22-capi-lab

Thanks for using kind! 😊
Load pre-downloaded images into kind cluster
Image: "gcr.io/k8s-staging-cluster-api/capd-manager:v1.2.4" with ID "sha256:ce58906cdf5645b9a74274d85b56acc717c29be16019732fd7a647ad898dadc8" not yet present on node "kubecon-na-22-capi-lab-control-plane", loading...
Image: "k8s.gcr.io/cluster-api/cluster-api-controller:v1.2.4" with ID "sha256:59a7be1f86721c75bceb6d9a31f12846ae9c6984130301b943bb4bc90a9a8f95" not yet present on node "kubecon-na-22-capi-lab-control-plane", loading...
Image: "k8s.gcr.io/cluster-api/kubeadm-bootstrap-controller:v1.2.4" with ID "sha256:b0fa2436bbfa2e6c9f60175b82c0cb9d98e8d77c9659d9437d224cf25ec80000" not yet present on node "kubecon-na-22-capi-lab-control-plane", loading...
Image: "k8s.gcr.io/cluster-api/kubeadm-control-plane-controller:v1.2.4" with ID "sha256:bb531d56d11c3086b5b03db7e9e42f68b003fa39ad07d1ce6a8d22e669f8c23b" not yet present on node "kubecon-na-22-capi-lab-control-plane", loading...
Image: "quay.io/jetstack/cert-manager-cainjector:v1.9.1" with ID "sha256:11778d29f8cc283a72a84fbd68601a631fc7705fe2f12a70ea5df7ca3262dfe9" not yet present on node "kubecon-na-22-capi-lab-control-plane", loading...
Image: "quay.io/jetstack/cert-manager-controller:v1.9.1" with ID "sha256:8eaca4249b016e1e355957d357a39a0a8a837e1837054e8762fe7d1cd13051af" not yet present on node "kubecon-na-22-capi-lab-control-plane", loading...
Image: "quay.io/jetstack/cert-manager-webhook:v1.9.1" with ID "sha256:d3348bcdc1e7e39e655c3b17106fe2e2038cfd70d080a3ac89a9eaf3bd26fc3d" not yet present on node "kubecon-na-22-capi-lab-control-plane", loading...
Image: "gcr.io/kakaraparthy-devel/cluster-api-visualizer:v1.0.0" with ID "sha256:76f45f9fdeb341ab49094bc424dda68acb2c2e22f08b63c9b8855fe42b620f17" not yet present on node "kubecon-na-22-capi-lab-control-plane", loading...
Image: "gcr.io/kakaraparthy-devel/test-extension:v1.0.1" with ID "sha256:5f09148f8fbfcffea6738f07e60205b477dcec37df31e49ad8432886ec46f29d" not yet present on node "kubecon-na-22-capi-lab-control-plane", loading...
```

**Note** The following error can be ignored: `ERROR: failed to load image: command "docker exec --privileged ... already exists` as the image load works even if this error occurs.

Test kubectl:
```bash
kubectl get node
```

Should return:
```bash
NAME                                   STATUS   ROLES           AGE    VERSION
kubecon-na-22-capi-lab-control-plane   Ready    control-plane   3m5s   v1.25.2
```

Delete the kind cluster:
```bash
kind delete cluster --name=kubecon-na-22-capi-lab
```

Next: [Creating Your First Cluster With Cluster API](#next-creating-your-first-cluster-with-cluster-api)

## Windows
**Note**: Windows instructions are based on Windows 11 with Powershell and Docker Desktop 4.10.1 using WSL 2.

### Clone the tutorial repository

```bash
git clone https://github.com/ykakarap/kubecon-na-22-capi-lab
cd kubecon-na-22-capi-lab

$env:CLUSTERCTL_REPOSITORY_PATH = ([System.Uri](Get-Item .).FullName).AbsoluteUri + "/clusterctl/repository"
```

**Notes**:
* The `CLUSTERCTL_REPOSITORY_PATH` environment variable is required later so we're able to run the tutorial offline.
* You can also download the repository via this link if you don't have `git` installed: [main.zip](https://github.com/ykakarap/kubecon-na-22-capi-lab/archive/refs/heads/main.zip).

### Put the tutorial repo on the $PATH

This tutorial uses the base of the tutorial repo to place and execute binaries. To add the current directory - which should be `kubecon-na-22-capi-lab` to the $PATH run:

```bash
$env:path = (Get-Item .).FullName + ';' + $env:path
```

### Install Docker, kubectl, kind, clusterctl and helm

[Install Docker Desktop 4.10.1 on Windows](https://docs.docker.com/desktop/release-notes/#docker-desktop-4101).
**Note:** This tutorial works best on Docker Desktop 4.10.1. Newer versions of Docker Desktop may crash and cause system instability when running Cluster API.
Verify the Docker installation via:
```bash
docker version
docker ps
```

**Note**: Please ensure the Docker VM has at least 4 CPU, 10 GB RAM and 32 GB disk.

Install kubectl as documented in [Install and Set Up kubectl on Windows](https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/).

Verify kubectl via:
```bash
kubectl version --client -o yaml
```

At the time of this writing the above link will guide you to download a version 1.25 of the kubectl binary. [Based on the official Kubernetes version skew policy](https://kubernetes.io/releases/version-skew-policy/#kubectl) you will be able to use either 1.24, 1.25, or 1.26 of kubectl to follow the tutorial, which will have you create and upgrade Kubernetes clusters running versions 1.24 and 1.25.

Install kind v0.16.0 by downloading it from the [kind release page](https://github.com/kubernetes-sigs/kind/releases/tag/v0.16.0) and adding it to the path.

```bash
curl.exe -L https://github.com/kubernetes-sigs/kind/releases/download/v0.16.0/kind-windows-amd64 -o kind.exe
# Note: If you don't have curl installed, just download the binary manually and rename it to kind.exe.

kind version
```

Install clusterctl v1.2.4 by downloading it from the [ClusterAPI release page](https://github.com/kubernetes-sigs/cluster-api/releases/tag/v1.2.4) and adding it to the path.

```bash
curl.exe -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.2.4/clusterctl-windows-amd64.exe -o clusterctl.exe
# Note: If you don't have curl installed, just download the binary manually and rename it to clusterctl.exe.

clusterctl version
```

Install helm v3.10.0 by downloading it from the [Helm release page](https://github.com/helm/helm/releases/tag/v3.10.0) and adding it to the path.

```bash
# amd64
curl.exe -L https://get.helm.sh/helm-v3.10.0-windows-amd64.zip -o ./helm.zip
Expand-Archive ./helm.zip ./helm
mv .\helm\windows-amd64\helm.exe .

helm version
```

### Pre-download container images

As we don't want to rely on the conference WiFi please pre-pull the container images used in the tutorial via:

```bash
.\scripts\prepull-images.ps1
```

**Note** You might have to enable running scripts by executing `Set-ExecutionPolicy Unrestricted` in a PowerShell run as Administrator.

### Verification

This section describes steps to verify everything has been installed correctly.

Create the kind cluster: (including pre-loading images)
```bash
.\scripts\create-kind-cluster.ps1
```

Should return:
```bash
Creating cluster "kubecon-na-22-capi-lab" ...
 ✓ Ensuring node image (kindest/node:v1.25.2) 🖼
 ✓ Preparing nodes 📦
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹️
 ✓ Installing CNI 🔌
 ✓ Installing StorageClass 💾
Set kubectl context to "kind-kubecon-na-22-capi-lab"
You can now use your cluster with:

kubectl cluster-info --context kind-kubecon-na-22-capi-lab

Thanks for using kind! 😊
Load pre-downloaded images into kind cluster
Image: "gcr.io/k8s-staging-cluster-api/capd-manager:v1.2.4" with ID "sha256:ce58906cdf5645b9a74274d85b56acc717c29be16019732fd7a647ad898dadc8" not yet present on node "kubecon-na-22-capi-lab-control-plane", loading...
Image: "k8s.gcr.io/cluster-api/cluster-api-controller:v1.2.4" with ID "sha256:59a7be1f86721c75bceb6d9a31f12846ae9c6984130301b943bb4bc90a9a8f95" not yet present on node "kubecon-na-22-capi-lab-control-plane", loading...
Image: "k8s.gcr.io/cluster-api/kubeadm-bootstrap-controller:v1.2.4" with ID "sha256:b0fa2436bbfa2e6c9f60175b82c0cb9d98e8d77c9659d9437d224cf25ec80000" not yet present on node "kubecon-na-22-capi-lab-control-plane", loading...
Image: "k8s.gcr.io/cluster-api/kubeadm-control-plane-controller:v1.2.4" with ID "sha256:bb531d56d11c3086b5b03db7e9e42f68b003fa39ad07d1ce6a8d22e669f8c23b" not yet present on node "kubecon-na-22-capi-lab-control-plane", loading...
Image: "quay.io/jetstack/cert-manager-cainjector:v1.9.1" with ID "sha256:11778d29f8cc283a72a84fbd68601a631fc7705fe2f12a70ea5df7ca3262dfe9" not yet present on node "kubecon-na-22-capi-lab-control-plane", loading...
Image: "quay.io/jetstack/cert-manager-controller:v1.9.1" with ID "sha256:8eaca4249b016e1e355957d357a39a0a8a837e1837054e8762fe7d1cd13051af" not yet present on node "kubecon-na-22-capi-lab-control-plane", loading...
Image: "quay.io/jetstack/cert-manager-webhook:v1.9.1" with ID "sha256:d3348bcdc1e7e39e655c3b17106fe2e2038cfd70d080a3ac89a9eaf3bd26fc3d" not yet present on node "kubecon-na-22-capi-lab-control-plane", loading...
Image: "gcr.io/kakaraparthy-devel/cluster-api-visualizer:v1.0.0" with ID "sha256:76f45f9fdeb341ab49094bc424dda68acb2c2e22f08b63c9b8855fe42b620f17" not yet present on node "kubecon-na-22-capi-lab-control-plane", loading...
Image: "gcr.io/kakaraparthy-devel/test-extension:v1.0.1" with ID "sha256:5f09148f8fbfcffea6738f07e60205b477dcec37df31e49ad8432886ec46f29d" not yet present on node "kubecon-na-22-capi-lab-control-plane", loading...
```

**Note** The following error can be ignored: `ERROR: failed to load image: command "docker exec --privileged ... already exists` as the image load works even if this error occurs.

Test kubectl:
```bash
kubectl get node
```

Should return:
```bash
NAME                                   STATUS   ROLES           AGE    VERSION
kubecon-na-22-capi-lab-control-plane   Ready    control-plane   3m5s   v1.25.2
```

Delete the kind cluster:
```bash
kind delete cluster --name=kubecon-na-22-capi-lab
```

## Avoid GitHub rate-limiting when running the tutorial without the local clusterctl repository

**Note**: The tutorial uses a local clusterctl repository, so these steps are not required to run the tutorial,
they are just documented in case folks want to run the tutorial without the local repository.

clusterctl accesses GitHub to install Cluster API, to avoid rate-limiting please set up a GitHub token.

First, create a token as documented on the [GitHub website](https://docs.github.com/en/enterprise-server@3.4/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) (no permissions needed)

Export the `GITHUB_TOKEN` in your environment

Linux and macOS:
```bash
export GITHUB_TOKEN=<GITHUB_TOKEN>
```

Windows:
```bash
$env:GITHUB_TOKEN = "<GITHUB_TOKEN>"
```

Next: [Creating Your First Cluster With Cluster API](#next-creating-your-first-cluster-with-cluster-api)

## Next: Creating Your First Cluster With Cluster API

Now that you've prepared your local environment, [let's build our first Kubernetes cluster using Cluster API](1-your-first-cluster.md)!
