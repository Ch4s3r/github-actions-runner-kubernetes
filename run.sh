#!/usr/bin/env zsh
set -euo pipefail
export GITHUB_CONFIG_URL=https://github.com/Ch4s3r/github-actions-runner-kubernetes
export GITHUB_PAT=$GITHUB_COM_TOKEN

# curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode=644
# export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

NAMESPACE="arc-systems"
kubectl create ns "${NAMESPACE}" || true
helm upgrade -i arc \
    --namespace "${NAMESPACE}" \
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller
INSTALLATION_NAME="arc-runner-set"
NAMESPACE="arc-runners"
kubectl create ns "${NAMESPACE}" || true
kubectl create secret generic github-credentials \
  --namespace "${NAMESPACE}" \
  --from-literal=github_token="${GITHUB_PAT}" || true
helm upgrade -i "${INSTALLATION_NAME}" \
    --namespace "${NAMESPACE}" \
    --set githubConfigUrl="${GITHUB_CONFIG_URL}" \
    --set githubConfigSecret=github-credentials \
    --set containerMode.type=kubernetes \
    --set containerMode.kubernetesModeWorkVolumeClaim.accessModes[0]=ReadWriteOnce \
    --set containerMode.kubernetesModeWorkVolumeClaim.storageClassName=local-path \
    --set containerMode.kubernetesModeWorkVolumeClaim.resources.requests.storage=1Gi \
    --set minRunners=1 \
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set
#    --set runnerGroup=ghe-local-arc \
