# Github Actions runners on Kubernetes via [ARC](https://github.com/actions/actions-runner-controller)

## Quickstart

### Setup github token PAT:

```shell
export GITHUB_CONFIG_URL=https://github.com/Ch4s3r/github-actions-runner-kubernetes
export GITHUB_PAT=
```

### Create kubernetes cluster

Install k3s as kuebrnetes provider for example

```shell
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode=644
```

Link the local kubeconfig to have access to the kubernetes cluster via cli
```shell
mkdir -p $HOME/.kube
ln -s /etc/rancher/k3s/k3s.yaml $HOME/.kube/config
```

Verify you have access to it via cli

```shell
kubectl get pods -A
helm list -A
```

### Install ARC:

```shell
sh run.sh
```

### Uninstall k3s

```shell
/usr/local/bin/k3s-uninstall.sh
```