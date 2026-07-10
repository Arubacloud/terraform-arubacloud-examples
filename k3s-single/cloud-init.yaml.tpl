#cloud-config
# k3s single-node cluster bootstrap for Aruba Cloud.
# Installs k3s with the built-in Traefik ingress controller.
# Rendered by Terraform templatefile() — do not use this file directly.

package_update: true
package_upgrade: true

packages:
  - curl
  - open-iscsi
  - nfs-common

runcmd:
  # ── Kernel settings required by k3s ──────────────────────────────────────────
  - modprobe br_netfilter
  - modprobe overlay
  - |
    cat > /etc/sysctl.d/99-k3s.conf <<'EOF'
    net.bridge.bridge-nf-call-iptables  = 1
    net.bridge.bridge-nf-call-ip6tables = 1
    net.ipv4.ip_forward                 = 1
    EOF
  - sysctl --system

  # ── Install k3s ───────────────────────────────────────────────────────────────
  - |
    set -euo pipefail
    VM_IP="${vm_ip}"
    EXTRA_SANS="--tls-san $VM_IP"
%{ if cluster_domain != "" }
    EXTRA_SANS="$EXTRA_SANS --tls-san ${cluster_domain}"
%{ endif }
    curl -sfL https://get.k3s.io | \
      INSTALL_K3S_VERSION="${k3s_version}" \
      K3S_KUBECONFIG_MODE="644" \
      sh -s - \
        $EXTRA_SANS \
        --node-external-ip "$VM_IP"

  # ── Wait for cluster to be ready ─────────────────────────────────────────────
  - |
    echo "Waiting for k3s to be ready ..."
    for i in $(seq 1 30); do
      k3s kubectl get nodes 2>/dev/null | grep -q " Ready" && { echo "Cluster ready."; break; }
      [ "$i" = "30" ] && { echo "ERROR: k3s did not become ready in 5 minutes"; exit 1; }
      sleep 10
    done

  # ── Make kubeconfig accessible to ubuntu user ─────────────────────────────────
  - mkdir -p /home/ubuntu/.kube
  - |
    sed "s|https://127.0.0.1:6443|https://${vm_ip}:6443|g" \
      /etc/rancher/k3s/k3s.yaml > /home/ubuntu/.kube/config
  - chown -R ubuntu:ubuntu /home/ubuntu/.kube
  - chmod 600 /home/ubuntu/.kube/config

final_message: |
  k3s bootstrap complete.
  API: https://${vm_ip}:6443
  Fetch kubeconfig:
    ssh ubuntu@${vm_ip} 'cat ~/.kube/config' > ~/.kube/k3s-arubacloud.yaml
  Check cluster:
    kubectl --kubeconfig ~/.kube/k3s-arubacloud.yaml get nodes
  Logs: /var/log/cloud-init-output.log
