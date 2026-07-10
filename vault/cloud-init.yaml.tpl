#cloud-config
# HashiCorp Vault bootstrap for Aruba Cloud.
# Vault Community Edition via official HashiCorp APT repo.
# Raft integrated storage — no external database required.
# Rendered by Terraform templatefile() — do not use this file directly.

package_update: true
package_upgrade: true

packages:
  - curl
  - gnupg
  - jq
  - openssl

write_files:
  # Vault HCL configuration
  - path: /etc/vault.d/vault.hcl
    permissions: "0640"
    owner: "vault:vault"
    content: |
      ui           = true
      disable_mlock = true
      api_addr     = "https://${vm_ip}:8200"
      cluster_addr = "https://${vm_ip}:8201"

      storage "raft" {
        path    = "/opt/vault/data"
        node_id = "vault-node-1"
      }

      listener "tcp" {
        address       = "0.0.0.0:8200"
        tls_cert_file = "/etc/vault.d/tls/vault.crt"
        tls_key_file  = "/etc/vault.d/tls/vault.key"
      }

runcmd:
  # ── HashiCorp APT repository ──────────────────────────────────────────────────
  - |
    curl -fsSL https://apt.releases.hashicorp.com/gpg \
      | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
      https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
      > /etc/apt/sources.list.d/hashicorp.list
    apt-get update -q
    apt-get install -y vault=${vault_version}-*

  # ── Vault data directory ──────────────────────────────────────────────────────
  - mkdir -p /opt/vault/data
  - chown -R vault:vault /opt/vault/data
  - chmod 700 /opt/vault/data

  # ── Generate self-signed TLS certificate ─────────────────────────────────────
  - mkdir -p /etc/vault.d/tls
  - |
    VM_IP="${vm_ip}"
    SAN_LINE="IP:$VM_IP"
%{ if tls_san != "" }
    SAN_LINE="$SAN_LINE,DNS:${tls_san}"
%{ endif }
    openssl req -x509 -newkey rsa:4096 -nodes -days 3650 \
      -keyout /etc/vault.d/tls/vault.key \
      -out    /etc/vault.d/tls/vault.crt \
      -subj   "/CN=vault/O=Vault" \
      -addext "subjectAltName=$SAN_LINE"
    chown vault:vault /etc/vault.d/tls/vault.key /etc/vault.d/tls/vault.crt
    chmod 640         /etc/vault.d/tls/vault.key /etc/vault.d/tls/vault.crt

  # ── Enable and start Vault ────────────────────────────────────────────────────
  - systemctl enable --now vault

  # ── Wait for Vault to be ready ────────────────────────────────────────────────
  - |
    export VAULT_ADDR="https://127.0.0.1:8200"
    export VAULT_SKIP_VERIFY=true
    echo "Waiting for Vault to be ready ..."
    for i in $(seq 1 30); do
      vault status 2>/dev/null | grep -q "Initialized" && break
      [ "$i" = "30" ] && { echo "ERROR: Vault did not start in time"; exit 1; }
      sleep 5
    done

  # ── Initialize Vault (idempotent — skipped if already initialized) ────────────
  - |
    export VAULT_ADDR="https://127.0.0.1:8200"
    export VAULT_SKIP_VERIFY=true
    INIT_FILE="/root/vault-init.json"
    if vault status 2>/dev/null | grep -q "Initialized.*false"; then
      echo "Initializing Vault ..."
      vault operator init -key-shares=5 -key-threshold=3 -format=json \
        > "$INIT_FILE"
      chmod 600 "$INIT_FILE"
      echo "Vault initialized. Init output saved to $INIT_FILE"
      echo "IMPORTANT: Copy the unseal keys and root token to a secure location!"
    else
      echo "Vault already initialized — skipping init."
    fi

  # ── Unseal Vault (3 of 5 keys) ────────────────────────────────────────────────
  - |
    export VAULT_ADDR="https://127.0.0.1:8200"
    export VAULT_SKIP_VERIFY=true
    INIT_FILE="/root/vault-init.json"
    if vault status 2>/dev/null | grep -q "Sealed.*true" && [ -f "$INIT_FILE" ]; then
      echo "Unsealing Vault ..."
      for i in 0 1 2; do
        KEY=$(jq -r ".unseal_keys_b64[$i]" "$INIT_FILE")
        vault operator unseal "$KEY"
      done
      echo "Vault unsealed."
    fi

final_message: |
  Vault bootstrap complete.
  UI: https://${vm_ip}:8200/ui
  Set env:
    export VAULT_ADDR=https://${vm_ip}:8200
    export VAULT_SKIP_VERIFY=true
  Retrieve init output (unseal keys + root token):
    sudo cat /root/vault-init.json
  IMPORTANT: Move the init output off this server immediately.
  Logs: /var/log/cloud-init-output.log
