# MachineHealthChecks and Machine remediation

Now let's take a look at MachineHealthChecks and Machine remediation. A MachineHealthCheck checks the health of
Machines and triggers a replacement (i.e. remediation) of a Machine when it is unhealthy.

The ClusterClass we are using already has MachineHealthChecks configured for worker Nodes. For reference, this is the 
declarative block that defines the MachineHealthCheck for the "`default-worker`" MachineDeployment class in [the 
ClusterClass spec we originally installed](./yamls/clusterclasses/clusterclass-quick-start.yaml):

```yaml
  workers:
    machineDeployments:
    - class: default-worker
      template:
      ...
      machineHealthCheck:
        unhealthyConditions:
        - type: DemoNodeHealthy
          status: "False"
          timeout: 60s
```

Based on this configuration Cluster API created a MachineHealthCheck object for our MachineDeployment:

```bash
kubectl get machinedeployment,machinehealthcheck
```

Output:

```bash
NAME                                                               CLUSTER              REPLICAS   READY   UPDATED   UNAVAILABLE   PHASE       AGE     VERSION
machinedeployment.cluster.x-k8s.io/docker-cluster-one-md-0-np68x   docker-cluster-one   1                  1         1             ScalingUp   4m42s   v1.24.6

NAME                                                                CLUSTER              EXPECTEDMACHINES   MAXUNHEALTHY   CURRENTHEALTHY   AGE
machinehealthcheck.cluster.x-k8s.io/docker-cluster-one-md-0-np68x   docker-cluster-one   1                  100%           1                4m42s
```

As mentioned above MachineHealthChecks can be used to detect unhealthy Machines. This can be done by:
* checking for conditions on Nodes via `unhealthyConditions` or
* checking that new nodes come up within a certain timespan via `nodeStartupTimeout`.

Once a Machine is detected as unhealthy it will be drained, deleted and a new Machine is created as replacement.

In this example we are simulating an unhealthy Node via the `DemoNodeHealthy` condition. The MachineHealthCheck will monitor 
the Nodes of the MachineDeployment. As soon as the `DemoNodeHealthy` condition is detected the MachineHealthCheck will mark 
the Machine for remediation and the Machine will be drained, deleted and replaced by a new Machine.

Now let's first take a look at our current Machines:

```bash
kubectl get machine
```

Output:
```bash
NAME                                             CLUSTER              NODENAME                                         PROVIDERID                                                  PHASE     AGE     VERSION
docker-cluster-one-md-0-np68x-6f47ffdffb-zqvv7   docker-cluster-one   docker-cluster-one-md-0-np68x-6f47ffdffb-zqvv7   docker:////docker-cluster-one-md-0-np68x-6f47ffdffb-zqvv7   Running   3m40s   v1.24.6
docker-cluster-one-pkkxd-66wmm                   docker-cluster-one   docker-cluster-one-pkkxd-66wmm                   docker:////docker-cluster-one-pkkxd-66wmm                   Running   24m     v1.24.6
```

And the corresponding Nodes in the workload cluster:

```bash
kubectl --kubeconfig cluster-one.kubeconfig get node
```

Output:
```bash
NAME                                             STATUS   ROLES           AGE     VERSION
docker-cluster-one-md-0-np68x-6f47ffdffb-zqvv7   Ready    <none>          3m46s   v1.24.6
docker-cluster-one-pkkxd-66wmm                   Ready    control-plane   24m     v1.24.6
```

Then let's simulate a Node failure by setting the `DemoNodeHealthy` condition on the worker Node:

```bash
kubectl --kubeconfig cluster-one.kubeconfig patch node $(kubectl --kubeconfig cluster-one.kubeconfig get nodes -l 'node-role.kubernetes.io/control-plane notin ()' -o jsonpath={'.items[*].metadata.name'}) --subresource=status --type=json -p='[{"op": "add", "path": "/status/conditions/-", "value": {"type": "DemoNodeHealthy", "status": "False", "message": "Node is unhealthy"}}]'
```

When we now take another look at our Nodes, we should see that the Node is replaced:

```bash
kubectl --kubeconfig cluster-one.kubeconfig get no -w
```

Output:
```bash
# Initial state
NAME                                             STATUS   ROLES           AGE   VERSION
docker-cluster-one-md-0-np68x-6f47ffdffb-zqvv7   Ready    <none>          41s   v1.24.6
docker-cluster-one-pkkxd-66wmm                   Ready    control-plane   27m   v1.24.6
# Node is drained and deleted
docker-cluster-one-md-0-np68x-6f47ffdffb-zqvv7   Ready    <none>          56s   v1.24.6
docker-cluster-one-md-0-np68x-6f47ffdffb-zqvv7   Ready,SchedulingDisabled   <none>          56s   v1.24.6
docker-cluster-one-md-0-np68x-6f47ffdffb-zqvv7   Ready,SchedulingDisabled   <none>          56s   v1.24.6
docker-cluster-one-md-0-np68x-6f47ffdffb-zqvv7   Ready,SchedulingDisabled   <none>          56s   v1.24.6
# New Node comes up
docker-cluster-one-md-0-np68x-6f47ffdffb-hjrhp   NotReady                   <none>          0s    v1.24.6
docker-cluster-one-md-0-np68x-6f47ffdffb-hjrhp   NotReady                   <none>          0s    v1.24.6
docker-cluster-one-md-0-np68x-6f47ffdffb-hjrhp   NotReady                   <none>          0s    v1.24.6
docker-cluster-one-md-0-np68x-6f47ffdffb-hjrhp   NotReady                   <none>          4s    v1.24.6
docker-cluster-one-md-0-np68x-6f47ffdffb-hjrhp   NotReady                   <none>          5s    v1.24.6
docker-cluster-one-md-0-np68x-6f47ffdffb-hjrhp   NotReady                   <none>          5s    v1.24.6
docker-cluster-one-md-0-np68x-6f47ffdffb-hjrhp   NotReady                   <none>          5s    v1.24.6
docker-cluster-one-md-0-np68x-6f47ffdffb-hjrhp   NotReady                   <none>          6s    v1.24.6
docker-cluster-one-md-0-np68x-6f47ffdffb-hjrhp   NotReady                   <none>          6s    v1.24.6
docker-cluster-one-md-0-np68x-6f47ffdffb-hjrhp   NotReady                   <none>          6s    v1.24.6
# New Node is ready
docker-cluster-one-md-0-np68x-6f47ffdffb-hjrhp   Ready                      <none>          11s   v1.24.6
docker-cluster-one-md-0-np68x-6f47ffdffb-hjrhp   Ready                      <none>          11s   v1.24.6
docker-cluster-one-md-0-np68x-6f47ffdffb-hjrhp   Ready                      <none>          14s   v1.24.6
```

**Note**: Depending on the performance of your local machine this can take from a few seconds up to a few minutes.

Now let's take another look at our Machines. You should be able to see that the worker Machine has been replaced by a new Machine.

```bash
kubectl get machine
```

Output:
```bash
kubectl get machine
NAME                                             CLUSTER              NODENAME                                         PROVIDERID                                                  PHASE     AGE     VERSION
docker-cluster-one-md-0-np68x-6f47ffdffb-hjrhp   docker-cluster-one   docker-cluster-one-md-0-np68x-6f47ffdffb-hjrhp   docker:////docker-cluster-one-md-0-np68x-6f47ffdffb-hjrhp   Running   1m      v1.24.6
docker-cluster-one-pkkxd-66wmm                   docker-cluster-one   docker-cluster-one-pkkxd-66wmm                   docker:////docker-cluster-one-pkkxd-66wmm                   Running   24m     v1.24.6
```

## Upgrading to another Kubernetes version

Now that we explored Machine remediation. Let's take a look at how we can [upgrade to another Kubernetes version](5-upgrade-kubernetes-version.md).
