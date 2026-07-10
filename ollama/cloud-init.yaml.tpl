#cloud-config
# Ollama bootstrap for Aruba Cloud.
# Installs Ollama as a systemd service, optionally pulls models at bootstrap.
# Rendered by Terraform templatefile() — do not use this file directly.
#
# WARNING: Model pulls can take many minutes depending on model size.
# A 7B model is ~4 GB; a 13B model is ~8 GB; a 70B model is ~40 GB.

package_update: true
package_upgrade: true

packages:
  - curl

write_files:
  # Ollama systemd override to listen on all interfaces
  - path: /etc/systemd/system/ollama.service.d/override.conf
    content: |
      [Service]
      Environment="OLLAMA_HOST=0.0.0.0"

runcmd:
  # ── Install Ollama ────────────────────────────────────────────────────────────
  - curl -fsSL https://ollama.ai/install.sh | sh

  # ── Apply systemd override and restart ───────────────────────────────────────
  - systemctl daemon-reload
  - systemctl enable ollama
  - systemctl restart ollama

  # ── Wait for Ollama to be ready ───────────────────────────────────────────────
  - |
    echo "Waiting for Ollama..."
    for i in $(seq 1 30); do
      curl -sf http://localhost:11434/api/tags >/dev/null 2>&1 \
        && { echo "Ollama ready after $((i * 2))s"; break; }
      sleep 2
    done

  # ── Pull requested models ─────────────────────────────────────────────────────
%{ for model in preload_models ~}
  - |
    echo "Pulling model: ${model}"
    ollama pull ${model} && echo "Pulled ${model}" || echo "WARNING: failed to pull ${model}"
%{ endfor ~}

final_message: |
  Ollama bootstrap complete.
  API: http://<IP>:11434  (accessible from api_cidr only)
  List models: curl http://<IP>:11434/api/tags
  Pull a model: ollama pull llama3.2
  Run a model: ollama run llama3.2
  Logs: journalctl -u ollama -f
  cloud-init log: /var/log/cloud-init-output.log
