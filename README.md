# Github Actions runners on Kubernetes via [ARC](https://github.com/actions/actions-runner-controller)

## Quickstart

### Setup github token PAT:

```shell
export GITHUB_TOKEN=...
```

### Create kubernetes cluster:

```shell
k3d create cluster
```

### Install ARC:

```shell
sh run.sh
```
