# Upgrade Kubernetes Version

Let's walk through how easily Cluster API enables Kubernetes version upgrades.

**Table of Contents**

- [Upgrade Cluster](#upgrade-cluster)
- Next: [Lifecycle Hooks](#lifecycle-hooks)

## Upgrade Cluster

Assuming we haven't done any further topology changes since we last re-applied the original "docker-cluster-one" spec, we should have one control plane node and one worker node:

```sh
kubectl --kubeconfig cluster-one.kubeconfig get nodes
```

Output:

```
NAME                                            STATUS   ROLES           AGE    VERSION
docker-cluster-one-md-0-lq4f8-b59497b9d-xchpm   Ready    <none>          4d1h   v1.24.6
docker-cluster-one-mvthd-k7dwf                  Ready    control-plane   4d2h   v1.24.6
```

Let's go ahead and scale our control plane nodes back out to three so that we can demonstrate how Kubernetes version upgrades can be configured to apply in a rolling upgrade fashion:

```sh
kubectl apply -f yamls/clusters/docker-cluster-one-3-control-plane-replicas.yaml
```

Ouput:

```
cluster.cluster.x-k8s.io/docker-cluster-one configured
```

Let's wait a few minutes until we have three control plane nodes. Then your workload cluster will look like this:

```sh
kubectl --kubeconfig cluster-one.kubeconfig get nodes
```

Output:

```
NAME                                            STATUS   ROLES           AGE    VERSION
docker-cluster-one-md-0-lq4f8-b59497b9d-xchpm   Ready    <none>          4d1h   v1.24.6
docker-cluster-one-mvthd-8dssf                  Ready    control-plane   108s   v1.24.6
docker-cluster-one-mvthd-k7dwf                  Ready    control-plane   4d2h   v1.24.6
docker-cluster-one-mvthd-k87gv                  Ready    control-plane   36s    v1.24.6
```

Now let's upgrade our cluster to the newest version of Kubernetes! Once again using the idempotent model to submit a modified configuration of our "`docker-cluster-one`" Cluster with a newer version of Kubernetes. Here's [that modified spec](yamls/clusters/docker-cluster-one-3-control-plane-replicas-1.25.2.yaml).

Here's the diff:

```bash
diff yamls/clusters/docker-cluster-one-3-control-plane-replicas.yaml yamls/clusters/docker-cluster-one-3-control-plane-replicas-1.25.2.yaml
```

Output:

```bash
15c15
<     version: v1.24.6
---
>     version: v1.25.2 # Upgrade to 1.25.2
```

The above declares a modified spec that will result in a Kubernetes version upgrade to v1.25.2. Let's initiate that upgrade:

```bash
kubectl apply -f yamls/clusters/docker-cluster-one-3-control-plane-replicas-1.25.2.yaml
```

Output:

```bash
cluster.cluster.x-k8s.io/docker-cluster-one configured
```


When upgrading the version of Kubernetes on a cluster, Cluster API follows the official Kubernetes recommendation to upgrade control plane nodes first. Cluster API maintains control plane node configuration in the `KubeadmControlPlane` resource. Let's follow the progress of an upgrade by watching that resource for our Cluster:

```sh
kubectl get kubeadmcontrolplanes -l cluster.x-k8s.io/cluster-name=docker-cluster-one -w
```

Output:

```
NAME                       CLUSTER              INITIALIZED   API SERVER AVAILABLE   REPLICAS   READY   UPDATED   UNAVAILABLE   AGE   VERSION
docker-cluster-one-6gm59   docker-cluster-one   true          true                   4          3       1         1             64m   v1.25.2
docker-cluster-one-6gm59   docker-cluster-one   true          true                   4          3       1         1             65m   v1.25.2
docker-cluster-one-6gm59   docker-cluster-one   true          true                   4          3       1         1             65m   v1.25.2
docker-cluster-one-6gm59   docker-cluster-one   true          true                   4          4       1         0             65m   v1.25.2
docker-cluster-one-6gm59   docker-cluster-one   true          true                   4          4       1         0             65m   v1.25.2
docker-cluster-one-6gm59   docker-cluster-one   true          true                   4          4       1         0             67m   v1.25.2
docker-cluster-one-6gm59   docker-cluster-one   true          true                   4          4       1         0             67m   v1.25.2
docker-cluster-one-6gm59   docker-cluster-one   true          true                   4          4       1         0             68m   v1.25.2
docker-cluster-one-6gm59   docker-cluster-one   true          true                   3          3       1         0             68m   v1.25.2
docker-cluster-one-6gm59   docker-cluster-one   true          true                   3          3       1         0             68m   v1.25.2
docker-cluster-one-6gm59   docker-cluster-one   true          true                   3          3       1         0             68m   v1.25.2
docker-cluster-one-6gm59   docker-cluster-one   true          true                   3          3       1         0             68m   v1.25.2
docker-cluster-one-6gm59   docker-cluster-one   true          true                   4          3       2         1             68m   v1.25.2
docker-cluster-one-6gm59   docker-cluster-one   true          true                   4          3       2         1             68m   v1.25.2
docker-cluster-one-6gm59   docker-cluster-one   true          true                   4          3       2         1             69m   v1.25.2
docker-cluster-one-6gm59   docker-cluster-one   true          true                   4          4       2         0             69m   v1.25.2
docker-cluster-one-6gm59   docker-cluster-one   true          true                   4          4       2         0             69m   v1.25.2
docker-cluster-one-6gm59   docker-cluster-one   true          true                   4          4       2         0             69m   v1.25.2
docker-cluster-one-6gm59   docker-cluster-one   true          true                   4          3       2         1             70m   v1.25.2
docker-cluster-one-6gm59   docker-cluster-one   true          true                   4          2       2         2             70m   v1.25.2
docker-cluster-one-6gm59   docker-cluster-one   true          true                   4          2       2         2             70m   v1.25.2
docker-cluster-one-6gm59   docker-cluster-one   true          true                   4          2       2         2             71m   v1.25.2
docker-cluster-one-6gm59   docker-cluster-one   true          true                   3          3       2         0             71m   v1.25.2
docker-cluster-one-6gm59   docker-cluster-one   true          true                   3          3       2         0             71m   v1.25.2
docker-cluster-one-6gm59   docker-cluster-one   true          true                   4          3       3         1             71m   v1.25.2
docker-cluster-one-6gm59   docker-cluster-one   true          true                   4          3       3         1             71m   v1.25.2
docker-cluster-one-6gm59   docker-cluster-one   true          true                   4          3       3         1             72m   v1.25.2
docker-cluster-one-6gm59   docker-cluster-one   true          true                   4          3       3         1             72m   v1.25.2
docker-cluster-one-6gm59   docker-cluster-one   true          true                   4          3       3         1             72m   v1.25.2
docker-cluster-one-6gm59   docker-cluster-one   true          true                   4          3       3         1             72m   v1.25.2
docker-cluster-one-6gm59   docker-cluster-one   true          true                   4          4       3         0             72m   v1.25.2
docker-cluster-one-6gm59   docker-cluster-one   true          true                   4          4       3         0             72m   v1.25.2
docker-cluster-one-6gm59   docker-cluster-one   true          true                   4          4       3         0             75m   v1.25.2
docker-cluster-one-6gm59   docker-cluster-one   true          true                   3          3       3         0             75m   v1.25.2
```

That's a console-full! What we see above is the process of a rolling upgrade:

1. Add a new node with the updated configuration (in this case: running a newer version of Kubernetes).
2. Wait until the new node is Ready.
3. Gracefully delete one node.
4. Repeat until all node replicas have the updated configuration, and are Ready.

After all control plane replicas finish upgrading, worker nodes will begin upgrading as well using the same rolling upgrade strategy described above. After our Cluster upgrade is done we can see all nodes running the newer version of Kubernetes:

```sh
kubectl --kubeconfig cluster-one.kubeconfig get nodes -o wide
```

Output:

```
NAME                                             STATUS   ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
docker-cluster-one-6gm59-79462                   Ready    control-plane   14m   v1.25.2   172.18.0.6    <none>        Ubuntu 22.04.1 LTS   5.10.124-linuxkit   containerd://1.6.8
docker-cluster-one-6gm59-b47pq                   Ready    control-plane   17m   v1.25.2   172.18.0.8    <none>        Ubuntu 22.04.1 LTS   5.10.124-linuxkit   containerd://1.6.8
docker-cluster-one-6gm59-pzplz                   Ready    control-plane   20m   v1.25.2   172.18.0.9    <none>        Ubuntu 22.04.1 LTS   5.10.124-linuxkit   containerd://1.6.8
docker-cluster-one-md-0-nnsb9-599977b664-2r55t   Ready    <none>          10m   v1.25.2   172.18.0.7    <none>        Ubuntu 22.04.1 LTS   5.10.124-linuxkit   containerd://1.6.8
```

We can see evidence above that the control plane nodes were upgraded first: the worker node `docker-cluster-one-md-0-nnsb9-599977b664-2r55t` has a more recent age (`10m`) compared to the age of the control plane nodes (`14m`, `17m`, and `20m`).

## Lifecycle Hooks

The next topic after Cluster Upgrade we'll cover is [lifecycle hooks](lifecycle-hooks.md).
