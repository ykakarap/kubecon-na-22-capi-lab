# Cluster API Lab - KubeCon NA 2022

Did you know you can create and manage a fleet of Kubernetes clusters just as easily as deploying Pods? Learn how to leverage Cluster API to create, update and manage your infrastructure, whether in the cloud or on-premises. Cluster API brings declarative management of entire clusters to the infrastructure provider of your choice.

Using your local machine you will learn how to create a fleet of clusters with Cluster API, scale up and down the number of nodes, and run a one-touch upgrade of entire clusters, all in just a few minutes.

This tutorial is designed for people who have some experience managing Kubernetes, and are interested in a new approach to solving the problem of operating clusters. You will leave this tutorial with the skills to automate fleets of clusters running production-grade Kubernetes.

This tutorial focuses on showcasing Cluster API features with the Docker provider which is using Docker on the local machine.

For more details on this talk see the [KubeCon schedule.](https://kccncna2022.sched.com/event/1BZDs) [The slides that pair with this tutorial are here.](./slides.pdf)


**Note: Before attending the tutorial at KubeCon please run through the [prerequisites section](./prereqs.md) to ensure the best experience on the day.**

Sections:
* [Prerequisites](./prereqs.md)
* [Creating your first cluster with Cluster API](./your-first-cluster.md)
* [Deploying the Cluster API visualizer](./visualizer.md)
* [Changing the Cluster Topology](./cluster-topology.md)
* [MachineHealthChecks and Machine remediation](./machine-health-checks.md)
* [Upgrading to another Kubernetes version](./upgrade-kubernetes-version.md)
* [Cluster Lifecycle Hooks](./lifecycle-hooks.md)
* [Self-hosted management cluster](./self-hosted.md)
* [Deleting a cluster && cleaning up Cluster API](./deleting-clusters-and-cleaning-up.md)
