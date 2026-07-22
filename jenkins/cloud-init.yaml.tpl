#cloud-config
# Jenkins LTS bootstrap for Aruba Cloud.
# Java 21 (OpenJDK) + Jenkins LTS via official APT repository + nginx reverse proxy.
# Rendered by Terraform templatefile() — do not use this file directly.

package_update: true
package_upgrade: true

packages:
  - curl
  - gnupg
  - nginx
  - certbot
  - python3-certbot-nginx
  - openjdk-21-jdk-headless
  - fontconfig

write_files:
  # nginx reverse proxy — routes HTTP traffic to Jenkins on port 8080
  - path: /etc/nginx/sites-available/jenkins.conf
    content: |
      server {
          listen 80;
          server_name ${server_name};

          location / {
              proxy_pass          http://127.0.0.1:8080;
              proxy_http_version  1.1;
              proxy_set_header    Upgrade $$http_upgrade;
              proxy_set_header    Connection 'upgrade';
              proxy_set_header    Host $$host;
              proxy_set_header    X-Real-IP $$remote_addr;
              proxy_set_header    X-Forwarded-For $$proxy_add_x_forwarded_for;
              proxy_set_header    X-Forwarded-Proto $$scheme;
              proxy_read_timeout  90s;
              # Required for Jenkins CLI and pipeline log streaming
              proxy_buffering     off;
          }
      }

runcmd:
  # ── Jenkins APT repository ────────────────────────────────────────────────────
  - |
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
      -o /usr/share/keyrings/jenkins-keyring.asc
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
      https://pkg.jenkins.io/debian-stable binary/" \
      > /etc/apt/sources.list.d/jenkins.list
    apt-get update -q
    apt-get install -y jenkins

  # ── Set JENKINS_URL so build links are correct ────────────────────────────────
  - |
    mkdir -p /var/lib/jenkins
    cat > /var/lib/jenkins/jenkins.model.JenkinsLocationConfiguration.xml <<'EOF'
    <?xml version='1.1' encoding='UTF-8'?>
    <jenkins.model.JenkinsLocationConfiguration>
      <adminAddress>address not configured yet &lt;nobody@nowhere&gt;</adminAddress>
      <jenkinsUrl>${base_url}/</jenkinsUrl>
    </jenkins.model.JenkinsLocationConfiguration>
    EOF
    chown jenkins:jenkins /var/lib/jenkins/jenkins.model.JenkinsLocationConfiguration.xml

  # ── Enable and start Jenkins ──────────────────────────────────────────────────
  - systemctl daemon-reload
  - systemctl enable --now jenkins

  # ── nginx setup ───────────────────────────────────────────────────────────────
  - ln -sf /etc/nginx/sites-available/jenkins.conf /etc/nginx/sites-enabled/jenkins.conf
  - rm -f /etc/nginx/sites-enabled/default
  - nginx -t
  - systemctl enable --now nginx

  # ── Optional HTTPS via Let's Encrypt ─────────────────────────────────────────
  - |
    DOMAIN="${domain}"
    EAB_KID="${acme_eab_kid}"
    EAB_HMAC="${acme_eab_hmac_key}"
    if [ -n "$DOMAIN" ]; then
      CERTBOT_EAB=""
      if [ -n "$EAB_KID" ] && [ -n "$EAB_HMAC" ]; then
        CERTBOT_EAB="--server https://acme-api.actalis.com/acme/directory --eab-kid $EAB_KID --eab-hmac-key $EAB_HMAC"
      fi
      for i in $(seq 1 30); do
        curl -sf http://127.0.0.1:8080/login >/dev/null && break
        sleep 10
      done
      certbot --nginx \
        -d "$DOMAIN" \
        --non-interactive \
        --agree-tos \
        -m "admin@$DOMAIN" \
        --redirect \
        $CERTBOT_EAB \
        && echo "HTTPS configured." \
        || echo "WARNING: Certbot failed. Ensure DNS points to this IP and retry."
    fi

  - nginx -t && systemctl reload nginx

final_message: |
  Jenkins bootstrap complete.
  URL: ${base_url}
  Initial admin password:
    sudo cat /var/lib/jenkins/secrets/initialAdminPassword
  Logs: /var/log/cloud-init-output.log
