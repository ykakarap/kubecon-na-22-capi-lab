# Troubleshooting

If something isn't working as expected in this tutorial, try the following steps 

## 1) Ensure docker is working
If `kubectl`, `kind` or `clusterctl` return an error like the following:
```bash
Unable to connect to the server: net/http:TLS handshaked timeout
```
It's likely that Docker has become unresponsive. Troubleshooting depends on your system. If you're using Docker Desktop you may have to restart it and [restart the tutorial](#resetting-the-tutorial). If your using linux you may be able to troubleshoot by running `systemctl status docker` and reviewing the logs.

## 2) Check the state of the cluster using `clusterctl`
Run:
```bash
clusterctl describe cluster --show-conditions=true docker-cluster-one
```
The output of this command will show the specific steps that have failed for your cluster - e.g. Bootstrap failed means your answers might be found on the KubeadmConfig or in the DockerMachine object.

## 3) Check the state of specific objects

If you've identified an object that is not being correctly created or updated, you can look at more detailed information about it using `kubectl describe $OBJECT_TYPE $OBJECT_NAME`

To list these objects run `kubectl get -A $OBJECT_TYPE`
For clusters run:
```bash
kubectl get -A clusters
```
For machines run:
```bash
kubectl get -A machines
```

To see the details of specific resources use:

For clusters:
```bash
kubectl describe cluster -n docker-cluster-namespace docker-cluster-one #use the namespace and name of the desired cluster
```
For machines:
```bash
kubectl describe machine -n docker-cluster-namespace docker-cluster-one-md-fjkd-309127 #use the name of the desired machine
```

The list of conditions on objects, and the messages associated with them, may help point to which controller is responsible for the issue.

## 4) Check the underlying infrastructure
This tutorial uses Cluster API Provider Docker for infrastructure - that means that each node is running in a Docker container.

To see these containers run:
```bash
docker ps
```
With a single cluster `docker-cluster-one` with one control plane node and one worker node you should see output like the following:

```bash
0c7669d2b090   kindest/node:v1.24.6                 "/usr/local/bin/entr…"   30 seconds ago       Up 29 seconds                                              docker-cluster-one-md-0-x2qmh-5596d8b774-72nsr
69c412fd86d9   kindest/node:v1.24.6                 "/usr/local/bin/entr…"   About a minute ago   Up About a minute   45305/tcp, 127.0.0.1:45305->6443/tcp   docker-cluster-one-w2vpl-7bldj
48444f6c42f5   kindest/haproxy:v20210715-a6da3463   "haproxy -sf 7 -W -d…"   About a minute ago   Up About a minute   33877/tcp, 0.0.0.0:33877->6443/tcp     docker-cluster-one-lb
fb9dcfb50740   kindest/node:v1.25.2                 "/usr/local/bin/entr…"   4 minutes ago        Up 4 minutes        127.0.0.1:33369->6443/tcp              kubecon-na-22-capi-lab-control-plane
```
The first container in the list is the worker node. Its name - at the far right column - is `docker-cluster-one-md-0` followed by a suffix. `md-0` is the name of the MachineDeployment the worker is a part of.
The second container is the control plane node.
The third container is a load balancer used for the control plane.

## 5) Checking Cluster API component logs

You may be able to find useful information about your error in the logs of the Cluster API components. Searching error strings on this troubleshooting guide, or in [the Cluster API book](https://cluster-api.sigs.k8s.io/) may point to a solution for your problem.

For the CAPI (Core) controller manager:
```bash
 kubectl logs -n capd-system deployments/capd-controller-manager
```
For the CAPD (Docker infrastructure) controller manager:
```bash
 kubectl logs -n capi-system deployments/capi-controller-manager
```

For the CAPBK (Kubeadm bootstrap) controller manager:
```bash
 kubectl logs -n capi-kubeadm-bootstrap-system deployments/capi-kubeadm-bootstrap-controller-manager
```

For the CAPI Kubeadm control plane controller manager:
```bash
kubectl logs -n capi-kubeadm-control-plane-system deployments/capi-kubeadm-control-plane-controller-manager
```

## Resetting the tutorial
During the course of the tutorial you might end up in an unstable state. If you can't solve an issue, and you'd like to start the tutorial over again see our [cleaning up guide](./deleting-clusters-and-cleaning-up.md#cleaning-up-resources-created-by-this-tutorial)

## Docker space issues
Docker may run out of space for keeping volumes and images required for this tutorial. This can especially be the case if you're doing the tutorial in a pre-existing docker environment which may have hanging volumes and images.
To clean up space run:
```bash
docker system prune
```

## Fedora: Cluster never provisions
**You may need to do use superuser permissions (`sudo`) for the commands in this section.** 

When running this tutorial on a Fedora installation there is an issue that can prevent clusters from advancing past the `Provisioning` stage. 

This problem can cause system instability. The root cause is a resource leak when Docker runs haproxy with the default Fedora configuration.

To fix this issue you need to find the Docker systemd unit file. On most systems it should be at `/usr/lib/systemd/system/docker.service`. To find where it is on your system run:

```bash
systemctl status docker | grep loaded
```
Output:
```bash
     Loaded: loaded (/usr/lib/systemd/system/docker.service; enabled; vendor preset: disabled)
```
Open this file with a text editor:

e.g.
```bash
nano /usr/lib/systemd/system/docker.service
```

The file should have a section that looks like:
```bash
[Service]
Type=notify
# the default is not to use systemd for cgroups because the delegate issues still
# exists and systemd currently does not support the cgroup feature set required
# for containers run by docker
ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
ExecReload=/bin/kill -s HUP $MAINPID
TimeoutSec=0
RestartSec=2
Restart=always
```

Modify it by adding the `--default-ulimit nofile=65883:65883` argument to the `ExecStart` line. The line should look similar to the below:

```bash
ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock  --default-ulimit nofile=65883:65883
```

Write and exit the file, and reload the systemd config and Docker service using:
```bash
systemctl daemon-reload
systemctl restart docker
```

You can check the status of the Docker service using:
```bash
systemctl status docker

```

The output on a successful reconfiguration should look like the below 

```bash
● docker.service - Docker Application Container Engine
     Loaded: loaded (/usr/lib/systemd/system/docker.service; enabled; vendor preset: disabled)
     Active: active (running) since Wed 2022-10-19 14:31:51 BST; 13s ago
TriggeredBy: ● docker.socket
       Docs: https://docs.docker.com
   Main PID: 13857 (dockerd)
      Tasks: 49
     Memory: 40.9M
        CPU: 785ms
     CGroup: /system.slice/docker.service
             ├─ 13857 /usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock --default-ulimit nofile=65883:65883  #ulimit nofile limit is set
             ├─ 14040 /usr/bin/docker-proxy -proto tcp -host-ip 127.0.0.1 -host-port 41825 -container-ip 172.19.0.2 -container-port 6443
             ├─ 14066 /usr/bin/docker-proxy -proto tcp -host-ip 127.0.0.1 -host-port 38625 -container-ip 172.19.0.3 -container-port 6443
             └─ 14143 /usr/bin/docker-proxy -proto tcp -host-ip 127.0.0.1 -host-port 5000 -container-ip 172.19.0.4 -container-port 5000
```

Once this change is working a Fedora system should be able to run the load balancer container correctly.

## Too many open files

### Linux
When getting logs from CAPI or Kubernetes components you may see log lines containing the string "too many open files".
On Linux you can resolve this issue by setting inotify limits on your system.

To do so run:
```bash
sudo sysctl fs.inotify.max_user_watches=524288
sudo sysctl fs.inotify.max_user_instances=512
```

Verify these values by running:
```bash
sysctl -a | grep fs.inotify.max_user
```
## macOS
If this error occurs on macOS, you may need to update the version of Docker Desktop you're using.

## Windows
In Windows using Docker Desktop 4.10.1 with wsl 2 you may see this in the logs of containers in the Docker Desktop UI.

From a powershell interface enter the Docker Desktop WSL2 environment using:
```bash
wsl
```

Run:
```bash
sysctl fs.inotify.max_user_watches=524288
sysctl fs.inotify.max_user_instances=512
```
To change the values.

Verify the changes  by running:
```bash
sysctl -a | grep fs.inotify.max_user
```
## Failed to pre-load images into the DockerMachine

If the capd logs contain the line: "failed to pre-load images into the DockerMachine" you should run the prepull images script to ensure you have the images stored locally.

On macOS and Linux run:
```bash
./scripts/prepull-images.sh
```

Or on Windows:
```bash
.\scripts\prepull-images.ps1
```

## Additional troubleshooting resources

The following resource may help you to identify problems:
- [Kind troubleshooting](https://kind.sigs.k8s.io/docs/user/known-issues/)
- [Cluster API troubleshooting page](https://cluster-api.sigs.k8s.io/user/troubleshooting.html)
- [Docker troubleshooting](https://docs.docker.com/desktop/troubleshoot/topics/)