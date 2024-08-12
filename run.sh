# export GITHUB_REPOSITORY=https://github.com/Ch4s3r/github-actions-runner-kubernetes
# export GITHUB_TOKEN=

# k3d cluster create -i latest

helm install arc \
    --create-namespace \
    --namespace arc-systems \
    --set githubConfigSecret=github-token \
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller
helm install arc-runner-set \
    --create-namespace \
    --namespace arc-runners \
    --create-namespace \
    --set githubConfigUrl=$GITHUB_REPOSITORY \
    --set githubConfigSecret=github-token \
    --values gha-runner-scale-set-values.yaml \
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set
kubectl create secret generic github-token \
   --namespace=arc-runners \
   --from-literal=github_token=$GITHUB_TOKEN
kubectl create secret generic github-token \
   --namespace=arc-systems \
   --from-literal=github_token=$GITHUB_TOKEN

# --values gha-runner-scale-set-values.yaml \
# --set template.spec.containers.runner.image=catthehacker/ubuntu:full-22.04 \
# --set template.spec.containers.runner.command= \