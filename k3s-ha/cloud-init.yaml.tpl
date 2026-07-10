#cloud-config
# k3s HA control-plane node for Aruba Cloud.
# All three nodes share the same external MySQL datastore — no --cluster-init needed.
# Rendered by Terraform templatefile() — do not use this file directly.
#
# Node: ${node_name}
# Bootstrap takes 2-5 minutes per node.

package_update: true
package_upgrade: true

packages:
  - ca-certificates
  - curl

write_files:
  - path: /root/k3s-token.b64
    permissions: "0600"
    content: "${token_b64}"

  - path: /root/k3s-dsn.b64
    permissions: "0600"
    content: "${datastore_dsn_b64}"

runcmd:
  # ── Install k3s as HA server with external MySQL datastore ────────────────────
  - |
    K3S_TOKEN=$(base64 -d /root/k3s-token.b64)
    DSN=$(base64 -d /root/k3s-dsn.b64)
    rm -f /root/k3s-token.b64 /root/k3s-dsn.b64

    if [ "${k3s_version}" = "latest" ]; then
      curl -sfL https://get.k3s.io | \
        K3S_TOKEN="$K3S_TOKEN" \
        K3S_DATASTORE_ENDPOINT="$DSN" \
        sh -s - server \
          --node-name="${node_name}" \
          --disable=servicelb
    else
      curl -sfL https://get.k3s.io | \
        INSTALL_K3S_VERSION="${k3s_version}" \
        K3S_TOKEN="$K3S_TOKEN" \
        K3S_DATASTORE_ENDPOINT="$DSN" \
        sh -s - server \
          --node-name="${node_name}" \
          --disable=servicelb
    fi

final_message: |
  k3s node ${node_name} setup complete.
  Get kubeconfig (run on node-1): sudo cat /etc/rancher/k3s/k3s.yaml
  Node status:  sudo k3s kubectl get nodes
  Logs:         journalctl -u k3s -f
  cloud-init log: /var/log/cloud-init-output.log
