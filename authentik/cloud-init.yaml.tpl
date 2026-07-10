#cloud-config
# Authentik identity provider bootstrap for Aruba Cloud.
# Deployed via Docker Compose: PostgreSQL + Redis + Authentik server + worker.
# Rendered by Terraform templatefile() — do not use this file directly.
#
# Bootstrap takes 3-5 minutes. The setup wizard appears on first visit.

package_update: true
package_upgrade: true

packages:
  - ca-certificates
  - curl
  - gnupg

write_files:
  # Credentials stored base64-encoded
  - path: /root/authentik-pg.b64
    permissions: "0600"
    content: "${pg_pass_b64}"

  - path: /root/authentik-secret.b64
    permissions: "0600"
    content: "${secret_key_b64}"

  # Docker Compose stack
  - path: /opt/authentik/docker-compose.yml
    content: |
      services:
        postgresql:
          image: docker.io/library/postgres:16-alpine
          restart: unless-stopped
          healthcheck:
            test: ["CMD-SHELL", "pg_isready -d authentik -U authentik"]
            start_period: 20s
            interval: 30s
            retries: 5
            timeout: 5s
          volumes:
            - postgresql:/var/lib/postgresql/data
          environment:
            POSTGRES_PASSWORD: $${POSTGRES_PASSWORD}
            POSTGRES_USER: authentik
            POSTGRES_DB: authentik

        redis:
          image: docker.io/library/redis:alpine
          restart: unless-stopped
          healthcheck:
            test: ["CMD-SHELL", "redis-cli ping | grep PONG"]
            start_period: 20s
            interval: 30s
            retries: 5
            timeout: 3s
          command: --save 60 1 --loglevel warning
          volumes:
            - redis:/data

        server:
          image: ghcr.io/goauthentik/server:${authentik_version}
          restart: unless-stopped
          command: server
          environment:
            AUTHENTIK_REDIS__HOST: redis
            AUTHENTIK_POSTGRESQL__HOST: postgresql
            AUTHENTIK_POSTGRESQL__USER: authentik
            AUTHENTIK_POSTGRESQL__NAME: authentik
            AUTHENTIK_POSTGRESQL__PASSWORD: $${POSTGRES_PASSWORD}
            AUTHENTIK_SECRET_KEY: $${AUTHENTIK_SECRET_KEY}
          ports:
            - "9000:9000"
            - "9443:9443"
          depends_on:
            postgresql:
              condition: service_healthy
            redis:
              condition: service_healthy

        worker:
          image: ghcr.io/goauthentik/server:${authentik_version}
          restart: unless-stopped
          command: worker
          user: root
          environment:
            AUTHENTIK_REDIS__HOST: redis
            AUTHENTIK_POSTGRESQL__HOST: postgresql
            AUTHENTIK_POSTGRESQL__USER: authentik
            AUTHENTIK_POSTGRESQL__NAME: authentik
            AUTHENTIK_POSTGRESQL__PASSWORD: $${POSTGRES_PASSWORD}
            AUTHENTIK_SECRET_KEY: $${AUTHENTIK_SECRET_KEY}
          volumes:
            - /var/run/docker.sock:/var/run/docker.sock
          depends_on:
            postgresql:
              condition: service_healthy
            redis:
              condition: service_healthy

      volumes:
        postgresql:
        redis:

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

  # ── Start Authentik ───────────────────────────────────────────────────────────
  - |
    PG_PASS=$(base64 -d /root/authentik-pg.b64)
    SECRET_KEY=$(base64 -d /root/authentik-secret.b64)
    rm -f /root/authentik-pg.b64 /root/authentik-secret.b64
    printf "POSTGRES_PASSWORD=%s\nAUTHENTIK_SECRET_KEY=%s\n" "$PG_PASS" "$SECRET_KEY" \
      > /opt/authentik/.env
    chmod 600 /opt/authentik/.env
    cd /opt/authentik && docker compose up -d

  # ── Wait for Authentik to be ready ────────────────────────────────────────────
  - |
    echo "Waiting for Authentik (may take 3-5 minutes)..."
    for i in $(seq 1 72); do
      HTTP_CODE=$(curl -sk -o /dev/null -w "%%{http_code}" http://localhost:9000/-/health/ready/)
      [ "$HTTP_CODE" = "204" ] && { echo "Authentik ready after $((i * 5))s"; break; }
      sleep 5
    done

final_message: |
  Authentik bootstrap complete.
  Web UI: http://<IP>:9000  or  https://<IP>:9443
  Initial setup: http://<IP>:9000/if/flow/initial-setup/
  Logs: docker logs authentik-server-1 -f
  cloud-init log: /var/log/cloud-init-output.log
