#cloud-config
# Rocket.Chat bootstrap for Aruba Cloud.
# Rocket.Chat + MongoDB 7.0 deployed via Docker Compose.
# MongoDB replica set is required by Rocket.Chat for oplog tailing.
# Rendered by Terraform templatefile() — do not use this file directly.

package_update: true
package_upgrade: true

packages:
  - curl
  - ca-certificates
  - gnupg

write_files:
  # Admin password stored base64-encoded
  - path: /root/rc-admin.b64
    permissions: "0600"
    content: "${admin_pass_b64}"

  # Docker Compose — admin credentials injected at runtime
  - path: /opt/rocketchat/docker-compose.yml
    content: |
      services:
        rocketchat:
          image: registry.rocket.chat/rocketchat/rocket.chat:latest
          restart: unless-stopped
          environment:
            MONGO_URL: "mongodb://mongo:27017/rocketchat?replicaSet=rs0"
            MONGO_OPLOG_URL: "mongodb://mongo:27017/local?replicaSet=rs0"
            ROOT_URL: "http://localhost:3000"
            PORT: "3000"
            DEPLOY_PLATFORM: docker
            ADMIN_USERNAME: "${admin_username}"
            ADMIN_NAME: "${admin_fullname}"
            ADMIN_EMAIL: "${admin_email}"
            ADMIN_PASS: "PLACEHOLDER_ADMIN_PASS"
          depends_on:
            - mongo
          ports:
            - "3000:3000"

        mongo:
          image: mongo:7.0
          restart: unless-stopped
          volumes:
            - mongo_data:/data/db
          command: mongod --oplogSize 128 --replSet rs0

      volumes:
        mongo_data:

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
    systemctl enable docker
    systemctl start docker

  # ── Inject admin password into compose file ───────────────────────────────────
  - |
    python3 - << 'PYEOF'
import base64, os

admin_pass = base64.b64decode(open('/root/rc-admin.b64').read().strip()).decode()
os.unlink('/root/rc-admin.b64')

with open('/opt/rocketchat/docker-compose.yml') as f:
    config = f.read()

config = config.replace('PLACEHOLDER_ADMIN_PASS', admin_pass)

with open('/opt/rocketchat/docker-compose.yml', 'w') as f:
    f.write(config)
PYEOF

  # ── Start MongoDB and initialise replica set ──────────────────────────────────
  - |
    cd /opt/rocketchat
    docker compose up -d mongo

    # Wait for MongoDB to be ready
    for i in $(seq 1 30); do
      docker compose exec -T mongo mongosh --quiet --eval "db.runCommand({ping:1})" \
        >/dev/null 2>&1 && { echo "MongoDB ready after $((i * 5))s"; break; }
      sleep 5
    done

    # Initialise replica set (required by Rocket.Chat)
    docker compose exec -T mongo mongosh --quiet --eval \
      "rs.initiate({_id:'rs0',members:[{_id:0,host:'localhost:27017'}]})"

  # ── Start Rocket.Chat ─────────────────────────────────────────────────────────
  - |
    cd /opt/rocketchat
    docker compose up -d rocketchat

final_message: |
  Rocket.Chat bootstrap complete.
  URL:   http://<IP>:3000
  Login: ${admin_username} / your admin_password
  Allow 2-3 minutes for Rocket.Chat to fully initialise on first start.
  Logs: docker compose -f /opt/rocketchat/docker-compose.yml logs -f
  cloud-init log: /var/log/cloud-init-output.log
