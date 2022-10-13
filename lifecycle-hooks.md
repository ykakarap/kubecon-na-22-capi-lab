# Using Cluster Lifecycle Hooks

This guide covers how Cluster API's RuntimeSDK feature can be used to hook into key lifecycle events of the Cluster.
In this section we will create a simple `test-extension` that receives key lifecycle events of the cluster and prints them.

<!-- table of contens generated via: https://github.com/thlorenz/doctoc -->
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [Using Cluster Lifecycle Hooks](#using-cluster-lifecycle-hooks)
  - [Running the Extension](#running-the-extension)
  - [Register the Extension](#register-the-extension)
  - [Extension in Action](#extension-in-action)
<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Running the Extension

Firstly we will need a simple extension server that needs to run and be able to receive cluster lifecycle events. For this, lets create a deployment in the management cluster that will act as our extension server.

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

Let's first look at how the registration looks like:

```yaml
apiVersion: runtime.cluster.x-k8s.io/v1alpha1
kind: ExtensionConfig
metadata:
  name: printer-extension                      // Unique Registration Name
  annotations:
    runtime.cluster.x-k8s.io/inject-ca-from-secret: test-extension-system/test-extension-webhook-service-cert
spec:
  clientConfig:                                // Information to contact the extension server
    service:                                   // Reference to a service running in the management cluster
      name: test-extension-webhook-service
      namespace: test-extension-system
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
> If you are curious take a look at `.status.handlers` in the printer-extension resource by doing kubectl get extensionconfig printer-extension -o jsonpath='{.status.handlers}'. This lists down all the lifecycle events the extension server would like to receive.

## Extension in Action

Now that we have the extension server running and registered with Cluster API let's see it in action. The extension server is configured to receive the following events (non-exhaustive list):

- BeforeClusterUpgrade
- AfterControlPlaneUpgrade
- AfterClusterUpgrade
- BeforeClusterDelete

In this section we will upgrade the workload cluster and see that the extension server receives these events and logs them.  
In a new terminal tab let's start watching the logs of the extension server:

```bash
kubectl logs -n test-extension-system deployments/test-extension-manager -f
```

Go back to the previous tab and upgrade the workload cluster.
**TODO:** Reference to the section Upgrade section. Also add command to upgrade a workload section.

In the extension server you should see logs similar to:

```bash
...... other log lines
I1012 05:38:33.756269       1 handlers.go:63] "BeforeClusterUpgrade is called"
I1012 05:38:33.762795       1 handlers.go:165] "BeforeClusterUpgrade response is Success. retry: 0"
I1012 05:41:41.090068       1 handlers.go:97] "AfterControlPlaneUpgrade is called"
I1012 05:41:41.096599       1 handlers.go:165] "AfterControlPlaneUpgrade response is Success. retry: 0"
I1012 05:42:26.810778       1 handlers.go:114] "AfterClusterUpgrade is called"
```

Note that the workload cluster could take up to a few minutes to finish the upgrade. Each of the log lines above would take a few minutes in between to show up.
