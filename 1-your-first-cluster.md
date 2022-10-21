# Creating your first cluster with Cluster API

This guide covers setting up and using Cluster API using Docker infrastructure, which is the same way CAPI runs its end-to-end tests. To set up a Cluster using AWS, Azure, GCP and many more see the [CAPI quick-start guide](https://cluster-api.sigs.k8s.io/user/quick-start.html)

**Before starting this section ensure you've completed the [prerequisites](./0-prereqs.md).**

<!-- table of contents generated via: https://github.com/thlorenz/doctoc -->
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [Linux](#linux)
  - [The Management Cluster](#the-management-cluster)
  - [Your first workload cluster](#your-first-workload-cluster)
- [MacOS](#macos)
  - [The Management Cluster](#the-management-cluster-1)
  - [Your first workload cluster](#your-first-workload-cluster-1)
- [Windows](#windows)
  - [The Management Cluster](#the-management-cluster-2)
  - [Your first workload cluster](#your-first-workload-cluster-2)
- [Next: Cluster API Visualizer](#next-cluster-api-visualizer)
- [More information](#more-information)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


## Linux

### The Management Cluster

A Cluster API Management Cluster is a Kubernetes Cluster where the components that make up the CAPI control plane are installed. These components include the Custom Resources used to create and manage a cluster and the controllers that operate on them.

The first step in creating a management cluster is to create a Kubernetes cluster to host the CAPI components.

```bash
cd kubecon-na-22-capi-lab

sh ./scripts/prepull-images.sh
sh ./scripts/create-kind-cluster.sh
```

**Note** The following error can be ignored: `ERROR: failed to load image: command "docker exec --privileged ... already exists` as the image load works even if this error occurs.

Once the cluster has completed provisioning you should be able to check it's healthy using:

```bash
kubectl get nodes
```

In this case we're using the Docker infrastructure provider - so we need the Docker provider (CAPD), the Core Cluster API provider (CAPI), the Kubeadm Bootstrap provider (CAPBK) and the Kubeadm Control Plane provider (KCP) to be installed on the cluster. In addition we need Cert Manager to be installed on the system.


Cluster API's CLI - `clusterctl` is used to install the CAPI Management Cluster components - luckily it's able to handle installing all of the above as well as the Custom Resource Definitions used by the Cluster API controllers.

```bash
export CLUSTERCTL_REPOSITORY_PATH=$(pwd)/clusterctl/repository
export CLUSTER_TOPOLOGY=true
export EXP_RUNTIME_SDK=true
clusterctl init --infrastructure docker --config ./clusterctl/repository/config.yaml
```
**Notes:**
* The `--config` flag helps clusterctl work in offline mode. When connected to the internet you can do `clusterctl init --infrastructure docker` to install CAPI Management Cluster components.
* Please ensure `CLUSTERCTL_REPOSITORY_PATH` is set and points to the clusterctl repository.
* `CLUSTER_TOPOLOGY` and `EXP_RUNTIME_SDK` are feature flags used to enable ClusterClass and RuntimeSDK.

Each of the provider controllers is installed as a pod on the Kind cluster. Once they're up and running you have your very own management Cluster!

To verify:
```bash
kubectl get pods -A
```
Output:
```bash
NAMESPACE                           NAME                                                            READY    STATUS    RESTARTS   AGE
capd-system                         capd-controller-manager-6f9c9d56b-h722b                          1/1     Running   0          84s
capi-kubeadm-bootstrap-system       capi-kubeadm-bootstrap-controller-manager-75dcdf5f8-qdrl5        1/1     Running   0          85s
capi-kubeadm-control-plane-system   capi-kubeadm-control-plane-controller-manager-8685fc89d4-fdp5s   1/1     Running   0          84s
capi-system                         capi-controller-manager-6c7689f5b9-2rn2v                         1/1     Running   0          85s
cert-manager                        cert-manager-86b6c9bf4b-f7hc6                                    1/1     Running   0          101s
cert-manager                        cert-manager-cainjector-7d4868cf69-k8jx5                         1/1     Running   0          101s
cert-manager                        cert-manager-webhook-6cb6fbfc58-qzpvg                            1/1     Running   0          101s
kube-system                         coredns-6d4b75cb6d-8trn8                                         1/1     Running   0          5m27s
kube-system                         coredns-6d4b75cb6d-f76kw                                         1/1     Running   0          5m27s
kube-system                         etcd-kind-control-plane                                          1/1     Running   0          5m42s
kube-system                         kindnet-l6qp2                                                    1/1     Running   0          5m27s
kube-system                         kube-apiserver-kind-control-plane                                1/1     Running   0          5m39s
kube-system                         kube-controller-manager-kind-control-plane                       1/1     Running   0          5m39s
kube-system                         kube-proxy-2zgh8                                                 1/1     Running   0          5m27s
kube-system                         kube-scheduler-kind-control-plane                                1/1     Running   0          5m40s
local-path-storage                  local-path-provisioner-9cd9bd544-sglzs                           1/1     Running   0          5m27s

```
Once all of the pods are `Running` - to update the status run the above command again - it's time to move on to the next section.

### Your first workload cluster

So what can you do with a functioning management cluster? Create more Clusters! The first step in doing this is to create a `ClusterClass` - this is a template that defines the shape of one or more clusters.

```bash
kubectl apply -f yamls/clusterclasses/clusterclass-quick-start.yaml
```

Next we can create an actual Cluster, but first let's take a look at the Cluster object specification we've prepared (in this repo at [`yamls/clusters/docker-cluster-one.yaml`](yamls/clusters/1-docker-cluster-one.yaml)):

```yaml
apiVersion: cluster.x-k8s.io/v1beta1
kind: Cluster
metadata:
  name: "docker-cluster-one"             # The name of the Cluster.
  namespace: "default"                   # The namespace the Cluster will be created in.
spec:
  clusterNetwork:
    services:
      cidrBlocks: ["10.128.0.0/12"]      # The IP range of services in the Cluster.
    pods:
      cidrBlocks: ["192.168.0.0/16"]     # The IP range of pods in the Cluster.
    serviceDomain: "cluster.local"
  topology:
    class: quick-start                   # The name of the ClusterClass the Cluster is templated from.
    version: v1.24.6                     # The version of the Kubernetes Cluster.
    controlPlane:
      replicas: 1                        # The number of control plane nodes in the Cluster.
    workers:
      machineDeployments:                # A group of worker nodes that all have the same spec.
        - class: default-worker          # The name of the Class the MachineDeployment is templated from.
          name: md-0
          replicas: 1                    # The number of worker nodes in this MachineDeployment
```

The Cluster specification above defines some of the fundamental characteristics of our Cluster - its name, the version of Kubernetes to install, the number of nodes in the control plane, the number and type of worker nodes, as well as some details about networking.

Time to create the Cluster! It's as simple as using the yaml spec we've prepared:

```bash
kubectl apply -f yamls/clusters/1-docker-cluster-one.yaml
```

Now that the Cluster has been created we can watch it come into being with:
```bash
watch clusterctl describe cluster docker-cluster-one
```
The output should resemble:
```bash
NAME                                                              READY  SEVERITY  REASON                           SINCE  MESSAGE
Cluster/docker-cluster-one                                        False  Warning   ScalingUp                        4s     Scaling up control plane to 1 replicas (actual 0)
├─ClusterInfrastructure - DockerCluster/docker-cluster-one-dkfbw  True                                              3s
├─ControlPlane - KubeadmControlPlane/docker-cluster-one-xbqb2     False  Warning   ScalingUp                        4s     Scaling up control plane to 1 replicas (actual 0)
│ └─Machine/docker-cluster-one-xbqb2-gwr52                        False  Info      WaitingForBootstrapData          2s     1 of 2 completed
└─Workers
  └─MachineDeployment/docker-cluster-one-md-0-nrh7k               False  Warning   WaitingForAvailableMachines      4s     Minimum availability requires 1 replicas, current 0 available
    └─Machine/docker-cluster-one-md-0-nrh7k-75ddc4778f-vlph9      False  Info      WaitingForControlPlaneAvailable  3s     0 of 2 completed
```

Our cluster will also be visible to kind, and we can see it using

```bash
kind get clusters
```

To operate on the cluster we need to retrieve its kubeconfig.
```bash
kind get kubeconfig --name docker-cluster-one > cluster-one.kubeconfig
```

We can see the nodes in the cluster.

```bash
kubectl --kubeconfig cluster-one.kubeconfig get nodes
```

The output shows that our nodes aren't in a `Ready` state - this is because we haven't installed a CNI yet.

```bash
NAME                                              STATUS     ROLES           AGE     VERSION
docker-cluster-one-md-0-g6cf5-659f45c999-zlvb2   NotReady   <none>          3m4s    v1.25.0
docker-cluster-one-sl7l7-nw9qb                   NotReady   control-plane   3m17s   v1.25.0
```

To install Calico on the Cluster using our prepared yaml spec:

```bash
kubectl --kubeconfig cluster-one.kubeconfig apply -f yamls/cni/calico.yaml
```

With the deployment created, watch for the pods to come up.
```bash
watch kubectl --kubeconfig cluster-one.kubeconfig get pods -A
```

Once all pods are in a `Running` state, the cluster nodes will move to the `Ready` state, and `clusterctl` will show the Cluster is healthy.

```bash
kubectl --kubeconfig cluster-one.kubeconfig get nodes

clusterctl describe cluster docker-cluster-one
```
Next: [Cluster API Visualizer](#next-cluster-api-visualizer)

## MacOS

### The Management Cluster

A Cluster API Management Cluster is a Kubernetes Cluster where the components that make up the CAPI control plane are installed. These components include the Custom Resources used to create and manage a cluster and the controllers that operate on them.

The first step in creating a management cluster is to create a Kubernetes cluster to host the CAPI components.

```bash
cd kubecon-na-22-capi-lab

sh ./scripts/prepull-images.sh
sh ./scripts/create-kind-cluster.sh
```

**Note** The following error can be ignored: `ERROR: failed to load image: command "docker exec --privileged ... already exists` as the image load works even if this error occurs.

Once the cluster has completed provisioning you should be able to check it's healthy using:

```bash
kubectl get nodes
```

In this case we're using the Docker infrastructure provider - so we need the Docker provider (CAPD), the Core Cluster API provider (CAPI), the Kubeadm Bootstrap provider (CAPBK) and the Kubeadm Control Plane provider (KCP) to be installed on the cluster. In addition we need Cert Manager to be installed on the system.


Cluster API's CLI - `clusterctl` is used to install the CAPI Management Cluster components - luckily it's able to handle installing all of the above as well as the Custom Resource Definitions used by the Cluster API controllers.

```bash
export CLUSTERCTL_REPOSITORY_PATH=$(pwd)/clusterctl/repository
export CLUSTER_TOPOLOGY=true
export EXP_RUNTIME_SDK=true
clusterctl init --infrastructure docker --config ./clusterctl/repository/config.yaml
```
**Notes:**
* The `--config` flag helps clusterctl work in offline mode. When connected to the internet you can do `clusterctl init --infrastructure docker` to install CAPI Management Cluster components.
* Please ensure `CLUSTERCTL_REPOSITORY_PATH` is set and points to the clusterctl repository.
* `CLUSTER_TOPOLOGY` and `EXP_RUNTIME_SDK` are feature flags used to enable ClusterClass and RuntimeSDK.

Each of the provider controllers is installed as a pod on the Kind cluster. Once they're up and running you have your very own management Cluster!

To verify:
```bash
kubectl get pods -A
```
Output:
```bash
NAMESPACE                           NAME                                                            READY    STATUS    RESTARTS   AGE
capd-system                         capd-controller-manager-6f9c9d56b-h722b                          1/1     Running   0          84s
capi-kubeadm-bootstrap-system       capi-kubeadm-bootstrap-controller-manager-75dcdf5f8-qdrl5        1/1     Running   0          85s
capi-kubeadm-control-plane-system   capi-kubeadm-control-plane-controller-manager-8685fc89d4-fdp5s   1/1     Running   0          84s
capi-system                         capi-controller-manager-6c7689f5b9-2rn2v                         1/1     Running   0          85s
cert-manager                        cert-manager-86b6c9bf4b-f7hc6                                    1/1     Running   0          101s
cert-manager                        cert-manager-cainjector-7d4868cf69-k8jx5                         1/1     Running   0          101s
cert-manager                        cert-manager-webhook-6cb6fbfc58-qzpvg                            1/1     Running   0          101s
kube-system                         coredns-6d4b75cb6d-8trn8                                         1/1     Running   0          5m27s
kube-system                         coredns-6d4b75cb6d-f76kw                                         1/1     Running   0          5m27s
kube-system                         etcd-kind-control-plane                                          1/1     Running   0          5m42s
kube-system                         kindnet-l6qp2                                                    1/1     Running   0          5m27s
kube-system                         kube-apiserver-kind-control-plane                                1/1     Running   0          5m39s
kube-system                         kube-controller-manager-kind-control-plane                       1/1     Running   0          5m39s
kube-system                         kube-proxy-2zgh8                                                 1/1     Running   0          5m27s
kube-system                         kube-scheduler-kind-control-plane                                1/1     Running   0          5m40s
local-path-storage                  local-path-provisioner-9cd9bd544-sglzs                           1/1     Running   0          5m27s

```

Once all of the pods are `Running` - to update the status run the above command again - it's time to move on to the next section.

### Your first workload cluster

So what can you do with a functioning management cluster? Create more Clusters! The first step in doing this is to create a `ClusterClass` - this is a template that defines the shape of one or more clusters.

```bash
kubectl apply -f yamls/clusterclasses/clusterclass-quick-start.yaml
```

Next we can create an actual Cluster, but first let's take a look at the Cluster object specification we've prepared (in this repo at [`yamls/clusters/docker-cluster-one.yaml`](yamls/clusters/1-docker-cluster-one.yaml)):

```yaml
apiVersion: cluster.x-k8s.io/v1beta1
kind: Cluster
metadata:
  name: "docker-cluster-one"             # The name of the Cluster.
  namespace: "default"                   # The namespace the Cluster will be created in.
spec:
  clusterNetwork:
    services:
      cidrBlocks: ["10.128.0.0/12"]      # The IP range of services in the Cluster.
    pods:
      cidrBlocks: ["192.168.0.0/16"]     # The IP range of pods in the Cluster.
    serviceDomain: "cluster.local"
  topology:
    class: quick-start                   # The name of the ClusterClass the Cluster is templated from.
    version: v1.24.6                     # The version of the Kubernetes Cluster.
    controlPlane:
      replicas: 1                        # The number of control plane nodes in the Cluster.
    workers:
      machineDeployments:                # A group of worker nodes that all have the same spec.
        - class: default-worker          # The name of the Class the MachineDeployment is templated from.
          name: md-0
          replicas: 1                    # The number of worker nodes in this MachineDeployment
```

The Cluster specification above defines some of the fundamental characteristics of our Cluster - its name, the version of Kubernetes to install, the number of nodes in the control plane, the number and type of worker nodes, as well as some details about networking.

Time to create the Cluster! It's as simple as using the yaml spec we've prepared:

```bash
kubectl apply -f yamls/clusters/1-docker-cluster-one.yaml
```

Now that the Cluster has been created we can use `clusterctl` to describe its components:
```bash
clusterctl describe cluster docker-cluster-one
```
The output should resemble:
```bash
NAME                                                              READY  SEVERITY  REASON                           SINCE  MESSAGE
Cluster/docker-cluster-one                                        False  Warning   ScalingUp                        4s     Scaling up control plane to 1 replicas (actual 0)
├─ClusterInfrastructure - DockerCluster/docker-cluster-one-dkfbw  True                                              3s
├─ControlPlane - KubeadmControlPlane/docker-cluster-one-xbqb2     False  Warning   ScalingUp                        4s     Scaling up control plane to 1 replicas (actual 0)
│ └─Machine/docker-cluster-one-xbqb2-gwr52                        False  Info      WaitingForBootstrapData          2s     1 of 2 completed
└─Workers
  └─MachineDeployment/docker-cluster-one-md-0-nrh7k               False  Warning   WaitingForAvailableMachines      4s     Minimum availability requires 1 replicas, current 0 available
    └─Machine/docker-cluster-one-md-0-nrh7k-75ddc4778f-vlph9      False  Info      WaitingForControlPlaneAvailable  3s     0 of 2 completed
```

Our cluster will also be visible to kind, and we can see it using

```bash
kind get clusters
```

To operate on the cluster we need to retrieve its kubeconfig.
```bash
kind get kubeconfig --name docker-cluster-one > cluster-one.kubeconfig
```

We can see the nodes in the cluster.

```bash
kubectl --kubeconfig cluster-one.kubeconfig get nodes
```

The output shows that our nodes aren't in a `Ready` state - this is because we haven't installed a CNI yet.

```bash
NAME                                              STATUS     ROLES           AGE     VERSION
docker-cluster-one-md-0-g6cf5-659f45c999-zlvb2   NotReady   <none>          3m4s    v1.25.0
docker-cluster-one-sl7l7-nw9qb                   NotReady   control-plane   3m17s   v1.25.0
```

To install Calico on the Cluster using our prepared yaml spec:

```bash
kubectl --kubeconfig cluster-one.kubeconfig apply -f yamls/cni/calico.yaml
```

With the deployment created, watch for the pods to come up.
```bash
kubectl --kubeconfig cluster-one.kubeconfig get pods -A -w
```

Once all pods are in a `Running` state, the cluster nodes will move to the `Ready` state, and `clusterctl` will show the Cluster is healthy.

```bash
kubectl --kubeconfig cluster-one.kubeconfig get nodes

clusterctl describe cluster docker-cluster-one
```
Next: [Cluster API Visualizer](#next-cluster-api-visualizer)

## Windows

**NOTE** This guide assumes users are using Powershell in a Windows environment. For other environments, e.g. WSL2, the [Linux](#Linux) guide might be a better starting place.

### The Management Cluster

A Cluster API Management Cluster is a Kubernetes Cluster where the components that make up the CAPI control plane are installed. These components include the Custom Resources used to create and manage a cluster and the controllers that operate on them.

The first step in creating a management cluster is to create a Kubernetes cluster to host the CAPI components.

```bash
cd kubecon-na-22-capi-lab

.\scripts\prepull-images.ps1
.\scripts\create-kind-cluster.ps1
```

**Note** The following error can be ignored: `ERROR: failed to load image: command "docker exec --privileged ... already exists` as the image load works even if this error occurs.

Once the cluster has completed provisioning you should be able to check it's healthy using:

```bash
kubectl get nodes
```

In this case we're using the Docker infrastructure provider - so we need the Docker provider (CAPD), the Core Cluster API provider (CAPI), the Kubeadm Bootstrap provider (CAPBK) and the Kubeadm Control Plane provider (KCP) to be installed on the cluster. In addition we need Cert Manager to be installed on the system.


Cluster API's CLI - `clusterctl` is used to install the CAPI Management Cluster components - luckily it's able to handle installing all of the above as well as the Custom Resource Definitions used by the Cluster API controllers.

```bash
$env:CLUSTERCTL_REPOSITORY_PATH = ([System.Uri](Get-Item .).FullName).AbsoluteUri + "/clusterctl/repository"
$env:path = (Get-Item .).FullName + ';' + $env:path
$env:CLUSTER_TOPOLOGY = 'true'
$env:EXP_RUNTIME_SDK = 'true'
clusterctl init --infrastructure docker --config ./clusterctl/repository/config.yaml
```
**Notes:**
* The `--config` flag helps clusterctl work in offline mode. When connected to the internet you can do `clusterctl init --infrastructure docker` to install CAPI Management Cluster components.
* Please ensure `CLUSTERCTL_REPOSITORY_PATH` is set and points to the clusterctl repository.
* `CLUSTER_TOPOLOGY` and `EXP_RUNTIME_SDK` are feature flags used to enable ClusterClass and RuntimeSDK.

Each of the provider controllers is installed as a pod on the Kind cluster. Once they're up and running you have your very own management Cluster!

To verify:
```bash
kubectl get pods -A
```
Output:
```bash
NAMESPACE                           NAME                                                            READY    STATUS    RESTARTS   AGE
capd-system                         capd-controller-manager-6f9c9d56b-h722b                          1/1     Running   0          84s
capi-kubeadm-bootstrap-system       capi-kubeadm-bootstrap-controller-manager-75dcdf5f8-qdrl5        1/1     Running   0          85s
capi-kubeadm-control-plane-system   capi-kubeadm-control-plane-controller-manager-8685fc89d4-fdp5s   1/1     Running   0          84s
capi-system                         capi-controller-manager-6c7689f5b9-2rn2v                         1/1     Running   0          85s
cert-manager                        cert-manager-86b6c9bf4b-f7hc6                                    1/1     Running   0          101s
cert-manager                        cert-manager-cainjector-7d4868cf69-k8jx5                         1/1     Running   0          101s
cert-manager                        cert-manager-webhook-6cb6fbfc58-qzpvg                            1/1     Running   0          101s
kube-system                         coredns-6d4b75cb6d-8trn8                                         1/1     Running   0          5m27s
kube-system                         coredns-6d4b75cb6d-f76kw                                         1/1     Running   0          5m27s
kube-system                         etcd-kind-control-plane                                          1/1     Running   0          5m42s
kube-system                         kindnet-l6qp2                                                    1/1     Running   0          5m27s
kube-system                         kube-apiserver-kind-control-plane                                1/1     Running   0          5m39s
kube-system                         kube-controller-manager-kind-control-plane                       1/1     Running   0          5m39s
kube-system                         kube-proxy-2zgh8                                                 1/1     Running   0          5m27s
kube-system                         kube-scheduler-kind-control-plane                                1/1     Running   0          5m40s
local-path-storage                  local-path-provisioner-9cd9bd544-sglzs                           1/1     Running   0          5m27s

```

Once all of the pods are `Running` - to update the status run the above command again - it's time to move on to the next section.

### Your first workload cluster

So what can you do with a functioning management cluster? Create more Clusters! The first step in doing this is to create a `ClusterClass` - this is a template that defines the shape of one or more clusters.

```bash
kubectl apply -f yamls/clusterclasses/clusterclass-quick-start.yaml
```

Next we can create an actual Cluster, but first let's take a look at the Cluster object specification we've prepared (in this repo at [`yamls/clusters/docker-cluster-one.yaml`](yamls/clusters/1-docker-cluster-one.yaml)):

```yaml
apiVersion: cluster.x-k8s.io/v1beta1
kind: Cluster
metadata:
  name: "docker-cluster-one"             # The name of the Cluster.
  namespace: "default"                   # The namespace the Cluster will be created in.
spec:
  clusterNetwork:
    services:
      cidrBlocks: ["10.128.0.0/12"]      # The IP range of services in the Cluster.
    pods:
      cidrBlocks: ["192.168.0.0/16"]     # The IP range of pods in the Cluster.
    serviceDomain: "cluster.local"
  topology:
    class: quick-start                   # The name of the ClusterClass the Cluster is templated from.
    version: v1.24.6                     # The version of the Kubernetes Cluster.
    controlPlane:
      replicas: 1                        # The number of control plane nodes in the Cluster.
    workers:
      machineDeployments:                # A group of worker nodes that all have the same spec.
        - class: default-worker          # The name of the Class the MachineDeployment is templated from.
          name: md-0
          replicas: 1                    # The number of worker nodes in this MachineDeployment
```

The Cluster specification above defines some of the fundamental characteristics of our Cluster - its name, the version of Kubernetes to install, the number of nodes in the control plane, the number and type of worker nodes, as well as some details about networking.

Time to create the Cluster! It's as simple as using the yaml spec we've prepared:

```bash
kubectl apply -f yamls/clusters/1-docker-cluster-one.yaml
```

Now that the Cluster has been created we can use `clusterctl` to describe its components:
```bash
$env:NO_COLOR = 'true'; clusterctl describe cluster docker-cluster-one
```
The output should resemble:
```bash
NAME                                                              READY  SEVERITY  REASON                           SINCE  MESSAGE
Cluster/docker-cluster-one                                        False  Warning   ScalingUp                        4s     Scaling up control plane to 1 replicas (actual 0)
├─ClusterInfrastructure - DockerCluster/docker-cluster-one-dkfbw  True                                              3s
├─ControlPlane - KubeadmControlPlane/docker-cluster-one-xbqb2     False  Warning   ScalingUp                        4s     Scaling up control plane to 1 replicas (actual 0)
│ └─Machine/docker-cluster-one-xbqb2-gwr52                        False  Info      WaitingForBootstrapData          2s     1 of 2 completed
└─Workers
  └─MachineDeployment/docker-cluster-one-md-0-nrh7k               False  Warning   WaitingForAvailableMachines      4s     Minimum availability requires 1 replicas, current 0 available
    └─Machine/docker-cluster-one-md-0-nrh7k-75ddc4778f-vlph9      False  Info      WaitingForControlPlaneAvailable  3s     0 of 2 completed
```

Our cluster will also be visible to kind, and we can see it using

```bash
kind get clusters
```

To operate on the cluster we need to retrieve its kubeconfig.
```bash
kind get kubeconfig --name docker-cluster-one > cluster-one.kubeconfig
```

We can see the nodes in the cluster.

```bash
kubectl --kubeconfig cluster-one.kubeconfig get nodes
```

The output shows that our nodes aren't in a `Ready` state - this is because we haven't installed a CNI yet.

```bash
NAME                                              STATUS     ROLES           AGE     VERSION
docker-cluster-one-md-0-g6cf5-659f45c999-zlvb2   NotReady   <none>          3m4s    v1.25.0
docker-cluster-one-sl7l7-nw9qb                   NotReady   control-plane   3m17s   v1.25.0
```

To install Calico on the Cluster using our prepared yaml spec:

```bash
kubectl --kubeconfig cluster-one.kubeconfig apply -f yamls/cni/calico.yaml
```

With the deployment created, watch for the pods to come up.
```bash
kubectl --kubeconfig cluster-one.kubeconfig get pods -A -w
```

Once all pods are in a `Running` state, the cluster nodes will move to the `Ready` state, and `clusterctl` will show the Cluster is healthy.

```bash
kubectl --kubeconfig cluster-one.kubeconfig get nodes

$env:NO_COLOR = 'true'; clusterctl describe cluster docker-cluster-one
```
Next: [Cluster API Visualizer](#next-cluster-api-visualizer)

## Next: Cluster API Visualizer

Now you've built your first cluster, [let's install the Visualizer to better see how Cluster API will enable you to manage it](2-visualizer.md)!

## More information
- To set up a Cluster using AWS, Azure, GCP and many more see the [CAPI quick-start guide](https://cluster-api.sigs.k8s.io/user/quick-start.html)

