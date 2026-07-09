#cloud-config
# Uptime Kuma bootstrap for Aruba Cloud.

package_update: true
package_upgrade: true
packages:
  - git
  - curl
  - ca-certificates

runcmd:
  # Install Node.js 22 LTS from NodeSource
  - curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
  - apt-get install -y nodejs

  # Install pm2 globally
  - npm install -g pm2

  # Clone and install Uptime Kuma
  - git clone https://github.com/louislam/uptime-kuma.git /opt/uptime-kuma
  - cd /opt/uptime-kuma && npm run setup

  # Create a dedicated service user
  - useradd -r -s /usr/sbin/nologin -d /opt/uptime-kuma kuma
  - chown -R kuma:kuma /opt/uptime-kuma

  # Start with pm2 as the kuma user
  - |
    su - kuma -s /bin/bash -c "
      cd /opt/uptime-kuma
      pm2 start server/server.js --name uptime-kuma -- --port ${kuma_port}
      pm2 save
    "

  # Configure pm2 to start on boot (runs as root, starts kuma user processes)
  - env PATH=$PATH:/usr/bin pm2 startup systemd -u kuma --hp /opt/uptime-kuma
  - systemctl enable pm2-kuma

final_message: "Uptime Kuma is running on port ${kuma_port}. Open http://<SERVER_IP>:${kuma_port} to set up your account."
