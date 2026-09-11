{ pkgs, ... }:

{
  packages = [ pkgs.qemu pkgs.cloud-utils ];

  env.OVMF_CODE = "${pkgs.OVMF.fd}/FV/AAVMF_CODE.fd";
  env.OVMF_VARS = "${pkgs.OVMF.fd}/FV/AAVMF_VARS.fd";

  # Boots a disposable Ubuntu 24.04 (arm64) VM under QEMU/HVF, provisions k3s
  # in it via cloud-init, then installs the ARC controller + runner scale set
  # against that cluster. RUNNER_QOS=burstable applies requests < limits on
  # the runner pod (vs. the guaranteed/equal default) to compare scheduling
  # behavior under concurrent load.
  scripts.up.exec = ''
    set -euo pipefail

    VM_DIR="''${VM_DIR:-.vm}"
    VM_MEMORY_MB="''${VM_MEMORY_MB:-32768}"
    VM_CPUS="''${VM_CPUS:-8}"
    SSH_PORT="''${SSH_PORT:-2222}"
    API_PORT="''${API_PORT:-16443}"
    RUNNER_QOS="''${RUNNER_QOS:-guaranteed}"
    BASE_IMAGE="''${VM_DIR}/base/ubuntu-24.04-server-cloudimg-arm64.img"
    SSH_OPTS=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p "''${SSH_PORT}")

    mkdir -p "''${VM_DIR}/base"

    if [[ -f "''${VM_DIR}/qemu.pid" ]] && kill -0 "$(cat "''${VM_DIR}/qemu.pid")" 2>/dev/null; then
      kill "$(cat "''${VM_DIR}/qemu.pid")"
      while kill -0 "$(cat "''${VM_DIR}/qemu.pid")" 2>/dev/null; do sleep 1; done
    fi
    rm -f "''${VM_DIR}/qemu.pid" "''${VM_DIR}/overlay.qcow2" "''${VM_DIR}/seed.iso" \
          "''${VM_DIR}/AAVMF_VARS.fd" "''${VM_DIR}/kubeconfig" "''${VM_DIR}/user-data.yaml"

    [[ -f "''${BASE_IMAGE}" ]] || curl -fL -o "''${BASE_IMAGE}" \
      https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-arm64.img

    sed "s|__SSH_PUBKEY__|$(cat ~/.ssh/id_ed25519.pub)|" vm/user-data.yaml > "''${VM_DIR}/user-data.yaml"
    cloud-localds "''${VM_DIR}/seed.iso" "''${VM_DIR}/user-data.yaml" vm/meta-data.yaml

    qemu-img create -f qcow2 -F qcow2 -b "$(pwd)/''${BASE_IMAGE}" "''${VM_DIR}/overlay.qcow2" 40G
    cp "''${OVMF_VARS}" "''${VM_DIR}/AAVMF_VARS.fd"
    chmod +w "''${VM_DIR}/AAVMF_VARS.fd"

    # HVF hangs indefinitely right after the firmware banner on this host/qemu
    # combo (verified: tcg boots the same image fine in seconds). Using tcg
    # (software CPU emulation) instead — slower, but it actually completes.
    # ponytail: tcg is much slower than HVF for CPU-bound work; revisit HVF if
    # this qemu/macOS combo gets fixed upstream.
    qemu-system-aarch64 \
      -accel tcg -cpu max -M virt,highmem=on \
      -smp "''${VM_CPUS}" -m "''${VM_MEMORY_MB}" \
      -drive if=pflash,format=raw,readonly=on,file="''${OVMF_CODE}" \
      -drive if=pflash,format=raw,file="''${VM_DIR}/AAVMF_VARS.fd" \
      -drive if=virtio,format=qcow2,file="''${VM_DIR}/overlay.qcow2" \
      -drive if=virtio,format=raw,file="''${VM_DIR}/seed.iso" \
      -netdev "user,id=net0,hostfwd=tcp::''${SSH_PORT}-:22,hostfwd=tcp::''${API_PORT}-:6443" \
      -device virtio-net-pci,netdev=net0 \
      -display none -serial file:"''${VM_DIR}/console.log" -pidfile "''${VM_DIR}/qemu.pid" -daemonize

    echo "Waiting for SSH..."
    until ssh "''${SSH_OPTS[@]}" ubuntu@127.0.0.1 true 2>/dev/null; do sleep 2; done
    echo "Waiting for cloud-init (k3s install)..."
    ssh "''${SSH_OPTS[@]}" ubuntu@127.0.0.1 sudo cloud-init status --wait

    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -P "''${SSH_PORT}" \
      ubuntu@127.0.0.1:/etc/rancher/k3s/k3s.yaml "''${VM_DIR}/kubeconfig"
    sed "s#https://127.0.0.1:6443#https://127.0.0.1:''${API_PORT}#" "''${VM_DIR}/kubeconfig" > "''${VM_DIR}/kubeconfig.tmp"
    mv "''${VM_DIR}/kubeconfig.tmp" "''${VM_DIR}/kubeconfig"
    export KUBECONFIG="$(pwd)/''${VM_DIR}/kubeconfig"

    export GITHUB_CONFIG_URL=https://github.com/Ch4s3r/github-actions-runner-kubernetes
    INSTALLATION_NAME="arc-runner-set"

    NAMESPACE="arc-systems"
    helm upgrade -i arc \
        --namespace "''${NAMESPACE}" \
        --create-namespace \
        --version 0.14.1 \
        oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller

    RUNNER_QOS_ARGS=()
    if [[ "''${RUNNER_QOS}" == "burstable" ]]; then
      RUNNER_QOS_ARGS=(--set resources.requests.memory=2Gi --set resources.requests.cpu=1)
    fi

    NAMESPACE="arc-runners"
    helm upgrade -i "''${INSTALLATION_NAME}" \
        --namespace "''${NAMESPACE}" \
        --create-namespace \
        --set githubConfigUrl="''${GITHUB_CONFIG_URL}" \
        --set githubConfigSecret.github_token="''${GITHUB_PAT}" \
        -f gha-runner-scale-set-values.yaml \
        "''${RUNNER_QOS_ARGS[@]}" \
        --version 0.14.1 \
        oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set

    kubectl wait --for=condition=Ready node --all --timeout=300s
    kubectl -n arc-systems wait --for=condition=Available deployment --all --timeout=120s
    kubectl -n arc-runners get pods
  '';
}
