#cloud-config
# LiteLLM proxy bootstrap for Aruba Cloud.
# Deployed via Docker; provides an OpenAI-compatible API endpoint that routes
# to multiple LLM providers (OpenAI, Anthropic, Ollama, etc.).
# Rendered by Terraform templatefile() — do not use this file directly.

package_update: true
package_upgrade: true

packages:
  - ca-certificates
  - curl
  - gnupg

write_files:
  # Credentials stored base64-encoded
  - path: /root/litellm-master.b64
    permissions: "0600"
    content: "${master_key_b64}"

  - path: /root/litellm-openai.b64
    permissions: "0600"
    content: "${openai_key_b64}"

  - path: /root/litellm-anthropic.b64
    permissions: "0600"
    content: "${anthropic_key_b64}"

runcmd:
  # ── Install Docker CE ─────────────────────────────────────────────────────────
  - install -m 0755 -d /etc/apt/keyrings
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  - chmod a+r /etc/apt/keyrings/docker.asc
  - |
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
    https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    > /etc/apt/sources.list.d/docker.list
  - apt-get update -y
  - apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  - usermod -aG docker ubuntu

  # ── Build LiteLLM config and start ───────────────────────────────────────────
  - |
    MASTER_KEY=$(base64 -d /root/litellm-master.b64)
    OPENAI_KEY=$(base64 -d /root/litellm-openai.b64)
    ANTHROPIC_KEY=$(base64 -d /root/litellm-anthropic.b64)
    rm -f /root/litellm-master.b64 /root/litellm-openai.b64 /root/litellm-anthropic.b64

    mkdir -p /opt/litellm

    # Build provider model list
    cat > /opt/litellm/config.yaml << 'LITELLM_EOF'
    model_list:
    LITELLM_EOF

    if [ -n "$OPENAI_KEY" ]; then
      cat >> /opt/litellm/config.yaml << 'LITELLM_EOF'
      - model_name: gpt-4o
        litellm_params:
          model: openai/gpt-4o
          api_key: OPENAI_KEY_PLACEHOLDER
      - model_name: gpt-4o-mini
        litellm_params:
          model: openai/gpt-4o-mini
          api_key: OPENAI_KEY_PLACEHOLDER
    LITELLM_EOF
      sed -i "s/OPENAI_KEY_PLACEHOLDER/$OPENAI_KEY/g" /opt/litellm/config.yaml
    fi

    if [ -n "$ANTHROPIC_KEY" ]; then
      cat >> /opt/litellm/config.yaml << 'LITELLM_EOF'
      - model_name: claude-sonnet-4-6
        litellm_params:
          model: anthropic/claude-sonnet-4-6
          api_key: ANTHROPIC_KEY_PLACEHOLDER
    LITELLM_EOF
      sed -i "s/ANTHROPIC_KEY_PLACEHOLDER/$ANTHROPIC_KEY/g" /opt/litellm/config.yaml
    fi

    OLLAMA_BASE="${ollama_base_url}"
    if [ -n "$OLLAMA_BASE" ]; then
      cat >> /opt/litellm/config.yaml << LITELLM_EOF
      - model_name: ollama/llama3.2
        litellm_params:
          model: ollama/llama3.2
          api_base: $OLLAMA_BASE
    LITELLM_EOF
    fi

    chmod 600 /opt/litellm/config.yaml

    docker run -d \
      --name litellm \
      --restart unless-stopped \
      --env LITELLM_MASTER_KEY="$MASTER_KEY" \
      -v /opt/litellm/config.yaml:/app/config.yaml:ro \
      -p 4000:4000 \
      ghcr.io/berriai/litellm:${litellm_version} \
      --config /app/config.yaml \
      --port 4000

  # ── Wait for LiteLLM to be ready ─────────────────────────────────────────────
  - |
    echo "Waiting for LiteLLM..."
    for i in $(seq 1 30); do
      curl -sf http://localhost:4000/health >/dev/null 2>&1 \
        && { echo "LiteLLM ready after $((i * 5))s"; break; }
      sleep 5
    done

final_message: |
  LiteLLM bootstrap complete.
  API: http://<IP>:4000  (OpenAI-compatible, accessible from api_cidr only)
  Auth: Bearer <master_key>
  Models: curl -H "Authorization: Bearer <key>" http://<IP>:4000/models
  Health: curl http://<IP>:4000/health
  Logs: docker logs litellm -f
  cloud-init log: /var/log/cloud-init-output.log
