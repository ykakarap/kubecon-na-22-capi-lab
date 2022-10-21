# Upgrade Kubernetes Version

Let's walk through how easily Cluster API enables Kubernetes version upgrades.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [Upgrade Cluster](#upgrade-cluster)
- [Clean up Docker Cluster one](#clean-up-docker-cluster-one)
- [Next: Cluster Lifecycle Hooks](#next-cluster-lifecycle-hooks)
- [More information](#more-information)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

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

Now let's upgrade our cluster to the newest version of Kubernetes! Once again using the idempotent model to submit a modified configuration of our `docker-cluster-one` Cluster with a newer version of Kubernetes. Here's [that modified spec](yamls/clusters/5-docker-cluster-one-1.25.2.yaml).

Here's the diff:

```bash
diff yamls/clusters/1-docker-cluster-one.yaml yamls/clusters/5-docker-cluster-one-1.25.2.yaml
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
kubectl apply -f yamls/clusters/5-docker-cluster-one-1.25.2.yaml
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
docker-cluster-one-6sk59   docker-cluster-one   true          true                   2          1       1         1             27m   v1.25.2
docker-cluster-one-6sk59   docker-cluster-one   true          true                   2          1       1         1             27m   v1.25.2
docker-cluster-one-6sk59   docker-cluster-one   true          true                   2          1       1         1             27m   v1.25.2
docker-cluster-one-6sk59   docker-cluster-one   true          true                   2          1       1         1             27m   v1.25.2
docker-cluster-one-6sk59   docker-cluster-one   true          true                   2          2       1         0             27m   v1.25.2
docker-cluster-one-6sk59   docker-cluster-one   true          true                   2          2       1         0             29m   v1.25.2
docker-cluster-one-6sk59   docker-cluster-one   true          true                   2          2       1         0             29m   v1.25.2
docker-cluster-one-6sk59   docker-cluster-one   true          true                   1          1       1         0             29m   v1.25.2
docker-cluster-one-6sk59   docker-cluster-one   true          true                   1          1       1         0             29m   v1.25.2
```

That's a console-full! What we see above is the process of a rolling upgrade:

1. Add a new node with the updated configuration (in this case: running a newer version of Kubernetes).
2. Wait until the new node is Ready.
3. Gracefully delete one node.
4. Repeat until all node replicas have the updated configuration, and are Ready.

**Note**: As the update will take a bit, this is a great time to take a look at the cluster via the visualizer: [http://localhost:18081](http://localhost:18081)!

After all control plane replicas finish upgrading, worker nodes will begin upgrading as well using the same rolling upgrade strategy described above. After our Cluster upgrade is done we can see all nodes running the newer version of Kubernetes:

```sh
kubectl --kubeconfig cluster-one.kubeconfig get nodes -o wide
```

Output:
```
docker-cluster-one-6sk59-ptdmj                   Ready    control-plane   5m13s   v1.25.2   172.19.0.6    <none>        Ubuntu 22.04.1 LTS   5.19.12-200.fc36.x86_64   containerd://1.6.8
docker-cluster-one-md-0-9vfj6-589d4c8fff-hx49z   Ready    <none>          2m5s    v1.25.2   172.19.0.7    <none>        Ubuntu 22.04.1 LTS   5.19.12-200.fc36.x86_64   containerd://1.6.8
```

We can see evidence above that the control plane nodes were upgraded first: the worker node `docker-cluster-one-md-0-9vfj6-589d4c8fff-hx49z` has a more recent age (`2m5s`) compared to the age of the control plane nodes `5m13s`).

## Clean up Docker Cluster one

It's time to say goodbye to docker-cluster-one - it's been through a lot! To delete the cluster run:

```bash
kubectl delete cluster docker-cluster-one
```
Before moving onto the next section ensure it's properly deleted by running:
```bash
 kubectl get clusters
```

Output:
```bash
No resources found in default namespace.
```
## Next: Cluster Lifecycle Hooks

The next topic after Cluster upgrade we'll cover is [Cluster Lifecycle Hooks](6-lifecycle-hooks.md).

## More information
- To learn more about how upgrades work with Cluster Topology see [the ClusterClass upgrades section of the CAPI book.](https://cluster-api.sigs.k8s.io/tasks/experimental-features/cluster-class/operate-cluster.html#upgrade-a-cluster)