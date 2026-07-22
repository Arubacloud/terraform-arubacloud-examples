#cloud-config
# Drupal 10 bootstrap for Aruba Cloud.
# Apache2 + PHP 8.1 + Composer + Drush + Managed MySQL DBaaS.
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
  - php-apcu
  - default-mysql-client
  - curl
  - git
  - unzip
  - snapd

write_files:
  # DB and admin passwords base64-encoded to avoid shell special-character issues
  - path: /root/drupal-db.b64
    permissions: "0600"
    content: "${db_pass_b64}"

  - path: /root/drupal-admin.b64
    permissions: "0600"
    content: "${admin_pass_b64}"

  # Apache virtual host — DocumentRoot points to Drupal's web/ subdirectory
  - path: /etc/apache2/sites-available/drupal.conf
    content: |
      <VirtualHost *:80>
          ServerAdmin ${admin_email}
          DocumentRoot /var/www/drupal/web
          <Directory /var/www/drupal/web>
              Options FollowSymLinks
              AllowOverride All
              Require all granted
          </Directory>
          ErrorLog /var/log/apache2/drupal-error.log
          CustomLog /var/log/apache2/drupal-access.log combined
      </VirtualHost>

runcmd:
  # ── Apache setup ──────────────────────────────────────────────────────────────
  - a2enmod rewrite
  - a2ensite drupal.conf
  - a2dissite 000-default.conf
  - systemctl enable --now apache2

  # ── Install Composer globally ─────────────────────────────────────────────────
  # HOME must be set; cloud-init runcmd inherits a minimal environment with no HOME.
  - |
    export HOME=/root
    curl -sS https://getcomposer.org/installer \
      | php -- --install-dir=/usr/local/bin --filename=composer
    chmod +x /usr/local/bin/composer

  # ── Create Drupal 10 project ──────────────────────────────────────────────────
  # Composer downloads ~80 MB of dependencies; allow up to 10 minutes.
  - |
    export HOME=/root
    COMPOSER_ALLOW_SUPERUSER=1 /usr/local/bin/composer create-project \
      drupal/recommended-project:^10 /var/www/drupal \
      --no-interaction --no-progress 2>&1

  # ── Add Drush ─────────────────────────────────────────────────────────────────
  - |
    export HOME=/root
    cd /var/www/drupal
    COMPOSER_ALLOW_SUPERUSER=1 /usr/local/bin/composer require drush/drush --no-interaction 2>&1

  # ── Wait for DBaaS to be reachable (up to 15 min) ────────────────────────────
  # Use python3 socket instead of /dev/tcp — the latter is bash-only; cloud-init
  # runcmd runs under /bin/sh (dash on Ubuntu).
  # Keep python3 -c on a single line: multi-line heredocs break YAML block scalars
  # when unindented code appears at column 1 (parser misreads them as YAML keys).
  - |
    DB_HOST="${db_host}"
    echo "Waiting for MySQL at $DB_HOST:3306 ..."
    i=0
    while [ "$i" -lt 90 ]; do
      i=$((i + 1))
      python3 -c "import socket,sys; s=socket.create_connection(('$DB_HOST',3306),timeout=2); s.close()" 2>/dev/null && { echo "MySQL ready after $((i * 10))s"; break; }
      if [ "$i" = "90" ]; then
        echo "ERROR: MySQL did not become ready in 15 minutes"
        exit 1
      fi
      sleep 10
    done

  # ── Install Drupal via Drush ──────────────────────────────────────────────────
  - |
    set -eu
    DB_PASS=$(base64 -d /root/drupal-db.b64)
    ADMIN_PASS=$(base64 -d /root/drupal-admin.b64)
    cd /var/www/drupal
    vendor/bin/drush site:install standard \
      --db-url="mysql://${db_user}:$DB_PASS@${db_host}/${db_name}" \
      --site-name="${site_name}" \
      --site-mail="${admin_email}" \
      --account-name="${admin_user}" \
      --account-pass="$ADMIN_PASS" \
      --account-mail="${admin_email}" \
      --yes
    rm -f /root/drupal-db.b64 /root/drupal-admin.b64

  # ── Set ownership and permissions ─────────────────────────────────────────────
  - chown -R www-data:www-data /var/www/drupal
  - find /var/www/drupal/web -type d -exec chmod 755 {} \;
  - find /var/www/drupal/web -type f -exec chmod 644 {} \;
  - chmod 640 /var/www/drupal/web/sites/default/settings.php

  # ── Optional: HTTPS via Let's Encrypt ────────────────────────────────────────
  # Install certbot via snap (EFF-recommended; avoids universe-repo dependency).
  - snap install --classic certbot 2>&1 || true
  - ln -sf /snap/bin/certbot /usr/bin/certbot
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
  Drupal 10 bootstrap complete.
  Site:  ${site_url}
  Admin: ${site_url}/user/login  (login: ${admin_user})
  Bootstrap takes 15-20 minutes total (Composer + DBaaS wait).
  Logs: /var/log/cloud-init-output.log
