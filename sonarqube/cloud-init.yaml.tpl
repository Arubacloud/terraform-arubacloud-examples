#cloud-config
# SonarQube Community Edition bootstrap for Aruba Cloud.
# Local PostgreSQL database. Java 17 + SonarQube zip distribution.
# IMPORTANT: vm.max_map_count must be >= 524288 for the embedded Elasticsearch.
# Rendered by Terraform templatefile() — do not use this file directly.

package_update: true
package_upgrade: true

packages:
  - curl
  - unzip
  - postgresql
  - postgresql-client
  - openjdk-17-jdk-headless

write_files:
  - path: /root/sonar-db.b64
    permissions: "0600"
    content: "${db_pass_b64}"

  - path: /etc/sysctl.d/99-sonarqube.conf
    content: |
      vm.max_map_count=524288
      fs.file-max=131072

  - path: /etc/security/limits.d/99-sonarqube.conf
    content: |
      sonarqube   -   nofile   131072
      sonarqube   -   nproc    8192

  - path: /etc/systemd/system/sonarqube.service
    content: |
      [Unit]
      Description=SonarQube
      After=network.target postgresql.service

      [Service]
      Type=forking
      User=sonarqube
      Group=sonarqube
      ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
      ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
      Restart=on-failure
      LimitNOFILE=131072
      LimitNPROC=8192

      [Install]
      WantedBy=multi-user.target

runcmd:
  # ── Apply kernel settings immediately ──────────────────────────────────────────
  - sysctl --system

  # ── Decode secret, set up PostgreSQL, install SonarQube, write config ─────────
  - |
    set -euo pipefail
    DB_PASS=$(base64 -d /root/sonar-db.b64)
    rm -f /root/sonar-db.b64

    systemctl enable --now postgresql
    sudo -u postgres psql -c "CREATE USER sonarqube WITH PASSWORD '$DB_PASS';" 2>/dev/null || true
    sudo -u postgres psql -c "CREATE DATABASE sonarqube OWNER sonarqube;"      2>/dev/null || true

    SQ_VERSION="${sonarqube_version}"
    curl -sSfL \
      "https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-$SQ_VERSION.zip" \
      -o /tmp/sonarqube.zip
    unzip -q /tmp/sonarqube.zip -d /opt
    mv /opt/sonarqube-$SQ_VERSION /opt/sonarqube
    rm -f /tmp/sonarqube.zip

    cat > /opt/sonarqube/conf/sonar.properties <<CONF
sonar.jdbc.username=sonarqube
sonar.jdbc.password=$DB_PASS
sonar.jdbc.url=jdbc:postgresql://localhost/sonarqube
sonar.web.host=0.0.0.0
sonar.web.port=9000
sonar.search.javaOpts=-Xmx512m -Xms512m -XX:MaxDirectMemorySize=256m
sonar.web.javaOpts=-Xmx512m -Xms128m
sonar.ce.javaOpts=-Xmx512m -Xms128m
CONF

  # ── System user and permissions ───────────────────────────────────────────────
  - useradd --system --no-create-home --shell /bin/false sonarqube 2>/dev/null || true
  - chown -R sonarqube:sonarqube /opt/sonarqube

  # ── Start SonarQube ──────────────────────────────────────────────────────────
  - systemctl daemon-reload
  - systemctl enable --now sonarqube

final_message: |
  SonarQube bootstrap complete.
  URL: http://<IP>:9000
  Default credentials: admin / admin  (change on first login)
  SonarQube takes 2-3 minutes to start after cloud-init completes.
  Logs: /opt/sonarqube/logs/sonar.log
  cloud-init log: /var/log/cloud-init-output.log
