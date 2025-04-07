#!/usr/bin/env zsh
set -euo pipefail
# export GITHUB_CONFIG_URL=https://github.com/Ch4s3r/github-actions-runner-kubernetes
# export GITHUB_PAT=$GITHUB_TOKEN

# curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode=644
# export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

helm repo add jetstack https://charts.jetstack.io --force-update
helm upgrade \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true

helm repo add actions-runner-controller https://actions-runner-controller.github.io/actions-runner-controller
helm upgrade --install --namespace actions-runner-system --create-namespace\
  --set=authSecret.create=true\
  --set=authSecret.github_token="$GITHUB_COM_TOKEN"\
  --wait actions-runner-controller actions-runner-controller/actions-runner-controller

kubectl apply -f runnerdeployment.yaml

kubectl get runners -w