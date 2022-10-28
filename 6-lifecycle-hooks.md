# Using Cluster Lifecycle Hooks

This guide covers how Cluster API's RuntimeSDK feature can be used to hook into key lifecycle events of the Cluster with a so-called
Runtime Extension. In this section we will create a simple `test-extension` that receives key lifecycle events of the cluster and prints them.

![lifecycle hooks](images/8.png)

<!-- table of contents generated via: https://github.com/thlorenz/doctoc -->
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [Deploy the Extension](#deploy-the-extension)
- [Register the Extension](#register-the-extension)
- [Extension in Action](#extension-in-action)
  - [Create a new workload Cluster](#create-a-new-workload-cluster)
  - [Delete the Cluster](#delete-the-cluster)
  - [(Optional) Block Cluster deletion using Extension Server](#optional-block-cluster-deletion-using-extension-server)
- [Cleanup](#clean-up)
- [Next: Creating a self-hosted management cluster](#next-creating-a-self-hosted-management-cluster)
- [More information](#more-information)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Deploy the Extension

First, we will need a simple extension server that needs to run and be able to receive cluster lifecycle events. For this, lets create a deployment in the management cluster that will act as our extension server.

```bash
kubectl apply -f yamls/extension/test-extension-deployment.yaml
```

Note that the YAML also contains all necessary resources like Service, Certificates, etc that will make this extension server reachable from within the management cluster.

Let's verify that the extension server is running:

```bash
kubectl get deployments -n test-extension-system
```

The output should resemble:

```bash
NAME                     READY   UP-TO-DATE   AVAILABLE   AGE
test-extension-manager   1/1     1            1           30s
```

## Register the Extension

Now that we have a running extension server let's register it with Cluster API. This will inform Cluster API to call the extension server during key workload cluster lifecycle events.

Let's first take a look at the ExtensionConfig we will use to register the extension:

```yaml
apiVersion: runtime.cluster.x-k8s.io/v1alpha1
kind: ExtensionConfig
metadata:
  name: printer-extension                      # Unique Registration Name
  annotations:
    runtime.cluster.x-k8s.io/inject-ca-from-secret: test-extension-system/test-extension-webhook-service-cert
spec:
  clientConfig:                                # Information to contact the extension server
    service:                                   # Reference to a service running in the management cluster
      name: test-extension-webhook-service
      namespace: test-extension-system
  namespaceSelector:
    matchExpressions:                          # Match only Cluster in Namespace ns-lifecycle-hooks
    - key: "kubernetes.io/metadata.name"
      operator: "In"
      values:
      - "ns-lifecycle-hooks"
```

Let's register the extension using:

```bash
kubectl apply -f yamls/extension/test-extension-config.yaml
```

Let us now verify that the extension is properly registered and reachable:

```bash
kubectl get extensionconfig printer-extension -o jsonpath='{.status.conditions}'
```

The output should resemble:

```bash
[{"lastTransitionTime":"2022-10-12T04:55:44Z","status":"True","type":"Discovered"}]
```

> **Optional**  
> If you are curious, take a look at `.status.handlers` of the `printer-extension` ExtensionConfig by running:
> ```bash
> kubectl get extensionconfig printer-extension -o jsonpath='{.status.handlers}'
> ```
> This lists all lifecycle events the extension server supports.

## Extension in Action

Now that we have the extension server running and registered with Cluster API let's see it in action. The extension server is configured to receive the following events:

- `BeforeClusterCreate` - Receives an event before the cluster topology is created.
- `AfterControlPlaneInitialized` - Receives an event after the control plane is reachable for the first time.
- `BeforeClusterUpgrade` - Receives an event before the cluster topology is upgraded.
- `AfterControlPlaneUpgrade` - Receives an event after the control plane is upgraded and before the upgrade is propagated to MachineDeployments.
- `AfterClusterUpgrade` - Receives an event after the cluster is fully upgraded.
- `BeforeClusterDelete` - Receives an event before cluster is deleted.

### Create a new workload Cluster

In this section we will create a new workload cluster and observe that the extension server receives these events and logs them.

Create a new `docker-cluster-lifecycle-hooks` workload cluster.
```bash
kubectl apply -f yamls/clusters/6-docker-cluster-lifecycle-hooks.yaml
```

Since we are creating a new workload cluster we should see the `BeforeClusterCreate` and the `AfterControlPlaneInitialized` events logged by the extension server.

Let's take a look a the extension server logs to see the received events:

```bash
kubectl logs -n test-extension-system deployments/test-extension-manager
```

In the extension server you should see logs similar to:

```bash
...... other log lines
I1014 02:50:50.860237       1 handlers.go:47] "BeforeClusterCreate is called"
I1014 02:50:50.873831       1 handlers.go:165] "BeforeClusterCreate response is Success. retry: 0"
I1014 02:51:38.782571       1 handlers.go:80] "AfterControlPlaneInitialized is called"
```

Note that the workload cluster could take a few minutes to fully come up and each of the log lines above could take a few minutes to appear. Re-fetch the logs again to see the updates or you could also follow the logs using `kubectl logs -n test-extension-system deployments/test-extension-manager -f`.

### Delete the Cluster

In this section we will delete the `docker-cluster-lifecycle-hooks` cluster and observe that the extension server is receiving and logging the event.

> If you are feeling adventurous try [Block Cluster deletion using Extension Server](#optional-block-cluster-deletion-using-extension-server) to block the cluster deletion via the extension instead.

To delete the cluster run:

```bash
kubectl delete -n ns-lifecycle-hooks cluster docker-cluster-lifecycle-hooks --wait=false
```

Get the extension server logs:

```bash
kubectl logs -n test-extension-system deployments/test-extension-manager
```

In the extension server you should see logs similar to:

```bash
I1014 03:06:52.393668       1 handlers.go:131] "BeforeClusterDelete is called"
I1014 03:06:52.408447       1 handlers.go:165] "BeforeClusterDelete response is Success. retry: 0"
```

### (Optional) Block Cluster deletion using Extension Server

So far we used a simple extension server that only logs the lifecycle events. What if we wanted to do more with the lifecycle hooks? In this section we will see how lifecycle hooks can be used to do more than just log events.

Let's change our extension server's behavior to send a "blocking response" when it receives a `BeforeClusterDelete` event.

The extension server is pre-configured to always send an "allow response". Let's change this so that the extension server now sends a "blocking response" to the `BeforeClusterDelete` event.

```bash
kubectl patch configmap -n ns-lifecycle-hooks docker-cluster-lifecycle-hooks-test-extension-hookresponses --patch-file yamls/extension/block-patch.yaml
```

Now, let's try to delete the cluster.

```bash
kubectl delete -n ns-lifecycle-hooks cluster docker-cluster-lifecycle-hooks --wait=false
```

You should observe that the delete operation is blocked and in the extension server logs you should observe the following logs:

```bash
kubectl logs -n test-extension-system deployments/test-extension-manager
```

The logs should show:

```bash
...... other log lines
I1014 03:25:41.039429       1 handlers.go:131] "BeforeClusterDelete is called"
I1014 03:25:41.046028       1 handlers.go:165] "BeforeClusterDelete response is Success. retry: 5"
.....
```

Observe the `retry: 5` in the logs. The extension server is effectively telling the cluster to block the delete operation and re-check after 5 seconds. The management cluster calls the extension server every ~ 5 seconds till the extension sends back a `retry: 0`.

You could list the list of clusters to see that the cluster is not deleted.

```bash
kubectl get clusters -n ns-lifecycle-hooks
```

Output:

```bash
NAME                             PHASE      AGE   VERSION
docker-cluster-lifecycle-hooks   Deleting   39s   v1.24.6
```

Let's update the extension server to now send an "allow response".

```bash
kubectl patch configmap -n ns-lifecycle-hooks docker-cluster-lifecycle-hooks-test-extension-hookresponses --patch-file yamls/extension/allow-patch.yaml
```

Now the cluster deletion operation should go through and the `docker-cluster-lifecycle-hooks` cluster will eventually be deleted.

Let's list the cluster to make sure that the cluster is deleted:
```bash
kubectl get clusters -n ns-lifecycle-hooks
```

Output:

```bash
No resources found in ns-lifecycle-hooks namespace.
```

You should observe that the cluster was deleted and there are no more clusters.

## Clean up

Delete the ExtensionConfig that registers the extension server with the management cluster.

```bash
kubectl delete extensionconfig printer-extension
```

Delete the extension server that is running on the management cluster.

```bash
kubectl delete -f yamls/extension/test-extension-deployment.yaml
```

## Next: Creating a self-hosted management cluster

[Next let's see how Cluster API can manage its own management cluster!](7-self-hosted.md)

## More information
- To learn more about Runtime SDK and Lifecycle hooks see the [Lifecycle hooks section of the CAPI book.](https://cluster-api.sigs.k8s.io/tasks/experimental-features/runtime-sdk/implement-lifecycle-hooks.html)