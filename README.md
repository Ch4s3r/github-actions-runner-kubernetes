# Github Actions runners on Kubernetes via [ARC](https://github.com/actions/actions-runner-controller)

## Quickstart

### Setup github token PAT:

```shell
export GITHUB_CONFIG_URL=https://github.com/Ch4s3r/github-actions-runner-kubernetes
export GITHUB_PAT=
```

### Create kubernetes cluster and install ARC

The cluster is a disposable Ubuntu 24.04 (arm64) VM booted with QEMU and provisioned
with k3s via cloud-init — no minikube/Docker Desktop needed.

```shell
devenv shell   # or `direnv allow` once, then just `cd` into the repo
up
```

`up` tears down any previous VM, boots a fresh one, waits for k3s to come up, and
installs the ARC controller + runner scale set against it. Re-run `up` any time to get a
clean cluster. Overridable via env vars: `VM_MEMORY_MB` (default 32768), `VM_CPUS`
(default 8), `SSH_PORT` (default 2222), `API_PORT` (default 16443), and `RUNNER_QOS`
(`guaranteed` default — requests==limits on the runner pod — or `burstable`, which sets
requests below limits to allow node overcommit).

Verify access via cli:

```shell
kubectl get pods -A
helm list -A
```

To stop the VM without recreating it: `kill $(cat .vm/qemu.pid)`.