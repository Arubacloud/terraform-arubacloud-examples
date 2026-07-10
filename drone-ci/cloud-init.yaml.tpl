#cloud-config
# Drone CI bootstrap for Aruba Cloud.
# Drone Server + Drone Docker Runner, both running as Docker Compose services.
# Requires a Gitea OAuth2 application — see README for setup instructions.
# Rendered by Terraform templatefile() — do not use this file directly.

package_update: true
package_upgrade: true

packages:
  - curl
  - ca-certificates
  - gnupg

write_files:
  # Docker Compose file for Drone Server + Docker Runner
  - path: /opt/drone/docker-compose.yml
    permissions: "0600"
    content: |
      services:
        drone-server:
          image: drone/drone:2
          container_name: drone-server
          restart: unless-stopped
          ports:
            - "80:80"
          environment:
            DRONE_GITEA_SERVER: "${gitea_url}"
            DRONE_GITEA_CLIENT_ID: "${gitea_client_id}"
            DRONE_GITEA_CLIENT_SECRET: "${gitea_client_secret}"
            DRONE_RPC_SECRET: "${drone_rpc_secret}"
            DRONE_SERVER_HOST: "${drone_host}"
            DRONE_SERVER_PROTO: "http"
            DRONE_USER_CREATE: "username:${drone_admin_user},admin:true"
          volumes:
            - drone-data:/data

        drone-runner:
          image: drone/drone-runner-docker:1
          container_name: drone-runner
          restart: unless-stopped
          environment:
            DRONE_RPC_PROTO: "http"
            DRONE_RPC_HOST: "drone-server"
            DRONE_RPC_SECRET: "${drone_rpc_secret}"
            DRONE_RUNNER_CAPACITY: "2"
            DRONE_RUNNER_NAME: "drone-runner"
          volumes:
            - /var/run/docker.sock:/var/run/docker.sock
          depends_on:
            - drone-server

      volumes:
        drone-data:

runcmd:
  # ── Install Docker ────────────────────────────────────────────────────────────
  - |
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
      | tee /etc/apt/sources.list.d/docker.list
    apt-get update -qq
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

  # ── Start Drone via Docker Compose ────────────────────────────────────────────
  - systemctl enable docker
  - systemctl start docker
  - docker compose -f /opt/drone/docker-compose.yml up -d

final_message: |
  Drone CI bootstrap complete.
  URL: http://${drone_host}
  Log in with your Gitea account (${drone_admin_user} gets admin rights).
  Logs: docker compose -f /opt/drone/docker-compose.yml logs -f
  cloud-init log: /var/log/cloud-init-output.log
