# Github Actions runners on Kubernetes via [ARC](https://github.com/actions/actions-runner-controller)

## Quickstart

### Setup github token PAT:

```shell
export GITHUB_REPOSITORY=https://github.com/Ch4s3r/github-actions-runner-kubernetes
export GITHUB_TOKEN=
```

### Create kubernetes cluster:

```shell
k3d cluster create -i latest
```

### Install ARC:

```shell
sh run.sh
```
