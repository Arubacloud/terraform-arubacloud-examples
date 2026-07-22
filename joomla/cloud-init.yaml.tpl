#cloud-config
# Joomla bootstrap for Aruba Cloud.
# Apache2 + PHP 8.1 + Joomla CLI installer + Managed MySQL DBaaS.
# Rendered by Terraform templatefile() — do not use this file directly.

package_update: true
package_upgrade: true

packages:
  - apache2
  - libapache2-mod-php
  - php
  - php-mysql
  - php-xml
  - php-gd
  - php-curl
  - php-mbstring
  - php-zip
  - php-intl
  - php-opcache
  - php-json
  - mysql-client
  - curl
  - unzip
  - certbot
  - python3-certbot-apache

write_files:
  # DB and admin passwords base64-encoded to avoid shell special-character issues
  - path: /root/joomla-db.b64
    permissions: "0600"
    content: "${db_pass_b64}"

  - path: /root/joomla-admin.b64
    permissions: "0600"
    content: "${admin_pass_b64}"

  # Apache virtual host
  - path: /etc/apache2/sites-available/joomla.conf
    content: |
      <VirtualHost *:80>
          ServerAdmin ${admin_email}
          DocumentRoot /var/www/joomla
          <Directory /var/www/joomla>
              Options FollowSymLinks
              AllowOverride All
              Require all granted
          </Directory>
          ErrorLog /var/log/apache2/joomla-error.log
          CustomLog /var/log/apache2/joomla-access.log combined
      </VirtualHost>

runcmd:
  # ── Apache setup ──────────────────────────────────────────────────────────────
  - a2enmod rewrite
  - a2ensite joomla.conf
  - a2dissite 000-default.conf
  - systemctl enable --now apache2

  # ── Download and extract Joomla ───────────────────────────────────────────────
  - |
    JOOMLA_VERSION="${joomla_version}"
    mkdir -p /var/www/joomla
    curl -sSfL \
      "https://github.com/joomla/joomla-cms/releases/download/$JOOMLA_VERSION/Joomla_$${JOOMLA_VERSION}-Stable-Full_Package.tar.gz" \
      | tar -xz -C /var/www/joomla
    chown -R www-data:www-data /var/www/joomla

  # ── Wait for DBaaS to be reachable (up to 15 min) ────────────────────────────
  - |
    DB_HOST="${db_host}"
    echo "Waiting for MySQL at $DB_HOST:3306 ..."
    for i in $(seq 1 90); do
      (echo > /dev/tcp/$DB_HOST/3306) 2>/dev/null && { echo "MySQL ready after $((i * 10))s"; break; }
      [ "$i" = "90" ] && { echo "ERROR: MySQL did not become ready in 15 minutes"; exit 1; }
      sleep 10
    done

  # ── Install Joomla via CLI ────────────────────────────────────────────────────
  - |
    set -euo pipefail
    DB_PASS=$(base64 -d /root/joomla-db.b64)
    ADMIN_PASS=$(base64 -d /root/joomla-admin.b64)
    cd /var/www/joomla
    php installation/joomla.php install \
      --site-name="${site_name}" \
      --admin-user="${admin_fullname}" \
      --admin-username="${admin_user}" \
      --admin-password="$ADMIN_PASS" \
      --admin-email="${admin_email}" \
      --db-type=mysql \
      --db-host="${db_host}" \
      --db-user="${db_user}" \
      --db-pass="$DB_PASS" \
      --db-name="${db_name}" \
      --no-interaction
    rm -f /root/joomla-db.b64 /root/joomla-admin.b64

  # ── Remove installation directory (security requirement) ──────────────────────
  - rm -rf /var/www/joomla/installation

  # ── Set final ownership ───────────────────────────────────────────────────────
  - chown -R www-data:www-data /var/www/joomla

  # ── Optional: HTTPS via Let's Encrypt ────────────────────────────────────────
  - |
    DOMAIN="${domain}"
    EAB_KID="${acme_eab_kid}"
    EAB_HMAC="${acme_eab_hmac_key}"
    if [ -n "$DOMAIN" ]; then
      CERTBOT_EAB=""
      if [ -n "$EAB_KID" ] && [ -n "$EAB_HMAC" ]; then
        CERTBOT_EAB="--server https://acme-api.actalis.com/acme/directory --eab-kid $EAB_KID --eab-hmac-key $EAB_HMAC"
      fi
      certbot --apache \
        -d "$DOMAIN" \
        --non-interactive \
        --agree-tos \
        -m "${admin_email}" \
        --redirect \
        $CERTBOT_EAB \
        && echo "HTTPS configured successfully." \
        || echo "WARNING: Certbot failed. Ensure DNS points to this IP and retry."
    fi

  - systemctl restart apache2

final_message: |
  Joomla bootstrap complete.
  Site:  ${site_url}
  Admin: ${site_url}/administrator  (login: ${admin_user})
  Logs: /var/log/cloud-init-output.log
