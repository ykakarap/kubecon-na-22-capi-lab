# Cluster API visualizer

[Cluster API visualizer](https://github.com/Jont828/cluster-api-visualizer) is an Open Source project from Jonathan Tong. The Cluster API visualizer is deployed into a management cluster and provides a great visual overview over workload clusters. This makes Cluster API significantly more accessible and it's a lot easier to understand dependencies between Cluster API objects.

Deploy the Cluster API visualizer via:

```bash
helm install capi-visualizer ./yamls/visualizer/chart/cluster-api-visualizer -n observability --create-namespace --values ./yamls/visualizer/values.yaml
```

Ensure the visualizer is up and running:

```bash
kubectl -n observability get pod
```

Output:

```bash
NAME                               READY   STATUS    RESTARTS   AGE
capi-visualizer-5fd569b7c6-g7xx5   1/1     Running   0          49s
```

Open a port-forward to the UI:

```bash
kubectl port-forward -n observability svc/capi-visualizer 18081:8081
```

Access the UI via your browser under [http://localhost:18081](http://localhost:18081).

If the dashboard is slow to load - it could be quicker to go directly to the [cluster view for `docker-cluster-one`](http://localhost:18081/cluster?name=docker-cluster-one&namespace=default)
Explore your workload cluster(s)!

![visualizer](visualizer.png)

**Note**:
* The visualizer can be used during the next sections to get a better understanding of Cluster API and the changes we make to a Cluster.
* The visualizer UI loads some CSS files from the internet, so if you're entirely offline and the files are not cached already, it won't work.

## Next: Changing Cluster Topology

Now we're ready to explore more of the power of Cluster API, [let's first explore cluster topology](3-cluster-topology.md)!
