# Use Cluster API to change the Cluster Topology

[In the previous walk-through](./your-first-cluster.md) we demonstrated how to create a cluster using a standard declarative configuration. Now we will show how to leverage this declarative configuration to update cluster topology with ease.

**Table of Contents**

- [Scale out control plane nodes](#scale-out-control-plane-nodes)
  - [Scale from 1 to 3 control plane nodes](#scale-from-1-to-3-control-plane-nodes)
- [More scale operations](#more-scale-operations)
- [Add a new pool of worker nodes](#add-a-new-pool-of-worker-nodes)
- [Remove a worker node](#remove-a-worker-node)
- Next: [MachineHealthChecks and Remediation](#machinehealthchecks-and-remediation)

## What is Cluster Topology?

We define a cluster topology as the set of configurations that describe your cluster: a few examples are the number of control plane and worker nodes; the type of Machine hardware that underlies various nodes; regional distribution across nodes or node pools. You may also see this described as "cluster shape" elsewhere.

## Scale out control plane nodes

A common Kubernetes cluster maintenance activity is scaling out (or in) the number of control plane nodes in response to cluster activity. Because Cluster API configuration interfaces are in fact Kubernetes resources, there are a lot of ways to do this. We'll demonstrate using a variety of methods.

### Scale from 1 to 3 control plane nodes

Because we are leveraging the Kubernetes declarative model, we can simply refer to a desired configuration specification and rely upon Cluster API to evaluate what's different between the two.

Assuming that your "`docker-cluster-one`" Cluster still has its original configuration, you should have one control plane node:

```bash
kubectl --kubeconfig cluster-one.kubeconfig get nodes
```

Output:

```bash
NAME                                             STATUS   ROLES           AGE   VERSION
docker-cluster-one-md-0-nrh7k-75ddc4778f-vlph9   Ready    <none>          24m   v1.24.6
docker-cluster-one-xbqb2-tlmpb                   Ready    control-plane   24m   v1.24.6
```

Let's use the idempotent model to submit a modified configuration of our "`docker-cluster-one`" Cluster with 3 control plane replicas instead of 1. We've provided [a reference yaml of this updated configuration in this repo](yamls/clusters/docker-cluster-one-3-control-plane-replicas.yaml).

If you're on masOS or Linux you can diff this modified spec from the original spec used to create the "`docker-cluster-one`" Cluster:

```bash
diff yamls/clusters/docker-cluster-one.yaml yamls/clusters/docker-cluster-one-3-control-plane-replicas.yaml
```

Output:

```bash
17c17
<       replicas: 1
---
>       replicas: 3 # Replicas changed from 1 to 3
```

The above shows that the `yaml` specs are almost identical, with the only change being the `replicas` value on L17. By applying that modified spec to our kind management cluster we can achieve a control plane node scale out operation:

```bash
kubectl apply -f yamls/clusters/docker-cluster-one-3-control-plane-replicas.yaml
```

Output:

```bash
cluster.cluster.x-k8s.io/docker-cluster-one configured
```

Now we can watch the new control plane nodes come online:

```bash
kubectl --kubeconfig cluster-one.kubeconfig get nodes -w
```

An interesting note! As your cluster transitions from 1 to 2 control plane nodes, it will temporarily lose etcd quorum and the apiserver running on your cluster will briefly go offline. So your `kubectl -w` command will be interrupted. Re-run the same command again to resume watching your cluster nodes:

```bash
kubectl --kubeconfig cluster-one.kubeconfig get nodes -w
```

Output:

```bash
NAME                                             STATUS     ROLES           AGE   VERSION
docker-cluster-one-md-0-nrh7k-75ddc4778f-vlph9   Ready      <none>          86m   v1.24.6
docker-cluster-one-xbqb2-8wcbj                   NotReady   <none>          21s   v1.24.6
docker-cluster-one-xbqb2-tlmpb                   Ready      control-plane   86m   v1.24.6
docker-cluster-one-xbqb2-8wcbj                   NotReady   <none>          21s   v1.24.6
docker-cluster-one-xbqb2-8wcbj                   NotReady   control-plane   21s   v1.24.6
docker-cluster-one-xbqb2-8wcbj                   NotReady   control-plane   23s   v1.24.6
docker-cluster-one-xbqb2-8wcbj                   NotReady   control-plane   23s   v1.24.6
docker-cluster-one-xbqb2-8wcbj                   NotReady   control-plane   30s   v1.24.6
docker-cluster-one-xbqb2-8wcbj                   NotReady   control-plane   30s   v1.24.6
docker-cluster-one-xbqb2-8wcbj                   NotReady   control-plane   30s   v1.24.6
docker-cluster-one-xbqb2-8wcbj                   Ready      control-plane   31s   v1.24.6
docker-cluster-one-xbqb2-8wcbj                   Ready      control-plane   48s   v1.24.6
docker-cluster-one-xbqb2-8wcbj                   Ready      control-plane   48s   v1.24.6
docker-cluster-one-xbqb2-8wcbj                   Ready      control-plane   53s   v1.24.6
docker-cluster-one-xbqb2-sjlwm                   NotReady   <none>          0s    v1.24.6
docker-cluster-one-xbqb2-sjlwm                   NotReady   <none>          0s    v1.24.6
docker-cluster-one-xbqb2-sjlwm                   NotReady   <none>          0s    v1.24.6
docker-cluster-one-xbqb2-sjlwm                   NotReady   <none>          0s    v1.24.6
docker-cluster-one-xbqb2-sjlwm                   NotReady   <none>          2s    v1.24.6
docker-cluster-one-xbqb2-sjlwm                   NotReady   <none>          2s    v1.24.6
docker-cluster-one-xbqb2-sjlwm                   NotReady   <none>          7s    v1.24.6
docker-cluster-one-xbqb2-sjlwm                   NotReady   <none>          7s    v1.24.6
docker-cluster-one-xbqb2-sjlwm                   NotReady   <none>          7s    v1.24.6
docker-cluster-one-xbqb2-sjlwm                   Ready      <none>          10s   v1.24.6
docker-cluster-one-xbqb2-sjlwm                   Ready      <none>          10s   v1.24.6
docker-cluster-one-xbqb2-sjlwm                   Ready      <none>          12s   v1.24.6
```

## More scale operations

For such a simple cluster topology change against a single configuration, it's also possible to update our Cluster resource in-place. Let's use `kubectl edit` to do that.

```bash
kubectl edit cluster/docker-cluster-one
```

The above command will engage your locally configured editor (for example, most macOS and Linux environments will be configured to launch `vim`). You'll want to look for the yaml configuration at the path `spec.topology.controlPlane.replicas`. Based on our prior scale out the value should be `3`. Go ahead and change that back to `1`, and then save the changes in your editor:

Output after editing, saving, and exiting your editor:

```bash
cluster.cluster.x-k8s.io/docker-cluster-one edited
```

After a few minutes we should now see the cluster back to reporting 1 control plane node (note that we're pointing `kubectl` to our workload cluster below using the previously saved `cluster-one.kubeconfig` kubeconfig file):

```bash
kubectl --kubeconfig cluster-one.kubeconfig get nodes
```

Output:

```bash
NAME                                             STATUS   ROLES           AGE    VERSION
docker-cluster-one-md-0-nrh7k-75ddc4778f-vlph9   Ready    <none>          118m   v1.24.6
docker-cluster-one-xbqb2-8wcbj                   Ready    control-plane   31m    v1.24.6
```

We can do the same gesture to scale worker nodes as well. This time we want to edit the configuration at path `spec.topology.workers.machineDeployments`. We should only have one item in that array; change its `replicas` value from `1` to any other, larger value:

```bash
kubectl edit cluster/docker-cluster-one
```

Output after editing, saving, and exiting your editor:

```bash
cluster.cluster.x-k8s.io/docker-cluster-one edited
```

If you updated from `1` to `3`, you would see those `3` nodes gradually come online after the change to our Cluster's `spec.topology.workers.machineDeployments` `replicas` value:

```bash
kubectl --kubeconfig cluster-one.kubeconfig get nodes
```

Output:

```bash
NAME                                             STATUS   ROLES           AGE     VERSION
docker-cluster-one-md-0-nrh7k-75ddc4778f-lzfr4   Ready    <none>          7m44s   v1.24.6
docker-cluster-one-md-0-nrh7k-75ddc4778f-t28hd   Ready    <none>          7m40s   v1.24.6
docker-cluster-one-md-0-nrh7k-75ddc4778f-vlph9   Ready    <none>          131m    v1.24.6
docker-cluster-one-xbqb2-8wcbj                   Ready    control-plane   44m     v1.24.6
```

NOTE!: Because we're executing the above topology changes using the Docker provider, your local system may not have sufficient resources to run 4 nodes. If so, you can skip the control-plane scaling part and reduce the number of worker nodes to `2` from `3`.

Feel free to continue experimenting with scaling. When you're done and ready to move forward, let's go back to our original topology configuration of 1 control plane node and 1 worker node. It's easy to do that by simply reapplying our original Cluster spec, which declares that configuration:

```bash
kubectl apply -f yamls/clusters/docker-cluster-one.yaml
```

## Add a new pool of worker nodes

Now we can demonstrate how easily you can leverage the flexibility of Cluster API to add and remove pools of nodes. For the purposes of this doc, we'll re-use the existing "`default-worker`" MachineDeployment class; in other words, we'll define a discrete, new node set based on a pre-existing, common worker machine recipe.

For reference, this is the declarative block that defines the "`default-worker`" MachineDeployment class in [the ClusterClass spec we originally installed](./yamls/clusterclasses/clusterclass-quick-start.yaml):

```yaml
  workers:
    machineDeployments:
    - class: default-worker
      template:
        bootstrap:
          ref:
            apiVersion: bootstrap.cluster.x-k8s.io/v1beta1
            kind: KubeadmConfigTemplate
            name: quick-start-default-worker-bootstraptemplate
        infrastructure:
          ref:
            apiVersion: infrastructure.cluster.x-k8s.io/v1beta1
            kind: DockerMachineTemplate
            name: quick-start-default-worker-machinetemplate
```

We'll reference the above "`default-worker`" class in [an updated Cluster configuration that declares a second worker pool](yamls/clusters/docker-cluster-one-second-worker-pool.yaml).

The difference between this spec and the original spec used to create the "`docker-cluster-one`" Cluster:

```bash
diff yamls/clusters/docker-cluster-one.yaml yamls/clusters/docker-cluster-one-second-worker-pool.yaml
```

Output:

```bash
35a36,38
>         - class: default-worker # Adding a 2nd worker pool
>           name: md-1
>           replicas: 1
```

The above shows that we've added a new `MachineDeployment` called `md-1` (Our existing `MachineDeployment` is named `md-0`) to our new spec. By applying this modified spec to our kind management cluster we will initiate the creation of a new node, from this new node pool:

```bash
kubectl apply -f yamls/clusters/docker-cluster-one-second-worker-pool.yaml
```

Output:

```bash
cluster.cluster.x-k8s.io/docker-cluster-one configured
```

Let's watch those new nodes come online:

```bash
kubectl --kubeconfig cluster-one.kubeconfig get nodes -w
```

Output:

```bash
NAME                                             STATUS   ROLES           AGE   VERSION
docker-cluster-one-md-0-nrh7k-75ddc4778f-wwpg9   Ready    <none>          25h   v1.24.6
docker-cluster-one-xbqb2-bcjvj                   Ready    control-plane   26h   v1.24.6
docker-cluster-one-md-1-ksqwt-8489684d5b-fpgjs   NotReady                   <none>          0s    v1.24.6
docker-cluster-one-md-1-ksqwt-8489684d5b-fpgjs   NotReady                   <none>          46s   v1.24.6
docker-cluster-one-md-1-ksqwt-8489684d5b-fpgjs   NotReady                   <none>          46s   v1.24.6
docker-cluster-one-md-1-ksqwt-8489684d5b-fpgjs   Ready                      <none>          76s   v1.24.6
```

## Remove a worker node

We can now demonstrate how easy it is to "roll back" such a change, as well as show how to remove an existing node pool from your Cluster configuration. In our case it's as easy as reapplying the original Cluster spec, which only declares one "`md-0`" node pool:

```bash
kubectl apply -f yamls/clusters/docker-cluster-one.yaml
```

Once again, we should observe only one running worker node, in the "`md-0`" pool:

```bash
kubectl --kubeconfig cluster-one.kubeconfig get nodes
```

Output:

```bash
NAME                                            STATUS   ROLES           AGE    VERSION
docker-cluster-one-md-0-lq4f8-b59497b9d-xchpm   Ready    <none>          99m    v1.24.6
docker-cluster-one-mvthd-k7dwf                  Ready    control-plane   174m   v1.24.6
```

## MachineHealthChecks and Remediation

You are now in control of your Cluster's topology configuration! [Let's next explore MachineHealthChecks and Remediation for operational self-healing](machine-health-checks.md).
