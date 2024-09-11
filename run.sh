set -euo pipefail
# set -x GITHUB_REPOSITORY https://github.com/Ch4s3r/github-actions-runner-kubernetes
# set -x GITHUB_TOKEN $GITHUB_TOKEN

# docker build . -t ch4s3r/actions-runner:2.319.1-0

minikube delete
minikube start
# minikube image load ch4s3r/actions-runner:2.319.1-0
helm install arc \
    --create-namespace \
    --namespace arc-systems \
    --set githubConfigSecret=github-token \
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller
helm install arc-runner-set \
    --create-namespace \
    --namespace arc-runners \
    --set githubConfigUrl=$GITHUB_REPOSITORY \
    --set githubConfigSecret=github-token \
    --set minRunners=10 \
    --set containerMode.type=dind \
    --set template.spec.containers[0].name=runner \
    --set template.spec.containers[0].image=ch4s3r/actions-runner:2.319.1-1 \
    --set template.spec.containers[0].command[0]="/home/runner/run.sh" \
    --set runnerGroup=ghe-local-arc \
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set
kubectl create secret generic github-token \
   --namespace=arc-runners \
   --from-literal=github_token=$GITHUB_TOKEN
kubectl create secret generic github-token \
   --namespace=arc-systems \
   --from-literal=github_token=$GITHUB_TOKEN
k9s

# --values gha-runner-scale-set-values.yaml \
# --set template.spec.containers.runner.image=catthehacker/ubuntu:full-22.04 \
# --set template.spec.containers.runner.command= \
# --values gha-runner-scale-set-values.yaml \