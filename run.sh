# export GITHUB_TOKEN=...
# k3d create cluster

kubectl create ns arc-systems
kubectl create ns arc-runners
kubectl create secret generic github-token \
   --namespace=arc-runners \
   --from-literal=github_token=$GITHUB_TOKEN

helm install arc \
    --namespace arc-systems \
    --set githubConfigSecret=github-token \
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller

helm install arc-runner-set \
    --namespace arc-runners \
    --create-namespace \
    --set githubConfigUrl=https://github.com/Ch4s3r/github-actions-runner-kubernetes \
    --set githubConfigSecret=github-token \
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set