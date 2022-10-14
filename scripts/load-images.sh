# TODO: May be create a single load-images script that can be used both by first-cluster and self-hosted sections.

# Load CAPI
# FIXME(sbueringer)
kind -n docker-cluster-self-hosted load docker-image gcr.io/k8s-staging-cluster-api/capd-manager:v1.2.3 docker.io/sbueringer/cluster-api-controller:v1.2.4-preview k8s.gcr.io/cluster-api/kubeadm-bootstrap-controller:v1.2.3 k8s.gcr.io/cluster-api/kubeadm-control-plane-controller:v1.2.3

# Load cert-manager
kind -n docker-cluster-self-hosted load docker-image quay.io/jetstack/cert-manager-cainjector:v1.9.1 quay.io/jetstack/cert-manager-controller:v1.9.1 quay.io/jetstack/cert-manager-webhook:v1.9.1