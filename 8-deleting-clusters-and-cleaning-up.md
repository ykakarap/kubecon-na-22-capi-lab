# Deleting clusters and cleaning up

## Deleting clusters
Clusters managed by Cluster API can be deleted in the same way as any other Kubernetes object.

To delete an individual cluster by name run:

```bash
kubectl delete cluster docker-cluster-one
```
This delete operation ensures that the cluster and all of the objects that form part of the cluster e.g. Machines, Cluster Infrastructure, are correctly deleted. 

To delete all clusters managed by Cluster API run:

```bash
kubectl delete clusters --all -A
```

## Cleaning up resources created by this tutorial

All clusters created in this tutorial use the Docker infrastructure provider and can be managed using kind. To clean up every Kubernetes cluster created in the tutorial - returning your system to the state [before creating the management cluster](./1-your-first-cluster.md) run:

```bash
kind delete clusters --all
```

More information about cleaning up objects with Docker, including containers and volumes downloaded and created as part of this tutorial, can be found in the [Docker documentation](https://docs.docker.com/config/pruning/).