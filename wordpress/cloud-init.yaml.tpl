#cloud-config
# WordPress bootstrap template for Aruba Cloud.
# Rendered by Terraform templatefile() — do not use this file directly.
# Variables ($${...}) are replaced by Terraform at plan time.

package_update: true
package_upgrade: true

packages:
  - apache2
  - libapache2-mod-php
  - php
  - php-mysql
  - php-xml
  - php-mbstring
  - php-curl
  - php-gd
  - php-zip
  - php-intl
  - php-bcmath
  - php-imagick
  - mysql-client
  - curl
  - wget
  - unzip
  - certbot
  - python3-certbot-apache

write_files:
  # Apache virtual host
  - path: /etc/apache2/sites-available/wordpress.conf
    content: |
      <VirtualHost *:80>
          ServerAdmin ${wp_admin_email}
          DocumentRoot /var/www/html
          DirectoryIndex index.php index.html
          <Directory /var/www/html>
              Options FollowSymLinks
              AllowOverride All
              Require all granted
          </Directory>
          ErrorLog /var/log/apache2/wordpress-error.log
          CustomLog /var/log/apache2/wordpress-access.log combined
      </VirtualHost>

  # WordPress configuration — written before WordPress is extracted so
  # rsync does not overwrite it.  The DB password is embedded using a
  # PHP single-quoted string; ' and \ are pre-escaped by Terraform.
  - path: /root/wp-config.php
    permissions: '0640'
    content: |
      <?php
      define( 'DB_NAME',         '${db_name}' );
      define( 'DB_USER',         '${db_user}' );
      define( 'DB_PASSWORD',     '${db_password_php}' );
      define( 'DB_HOST',         '${db_host}' );
      define( 'DB_CHARSET',      'utf8mb4' );
      define( 'DB_COLLATE',      '' );
      define( 'AUTH_KEY',        '${auth_key}' );
      define( 'SECURE_AUTH_KEY', '${secure_auth_key}' );
      define( 'LOGGED_IN_KEY',   '${logged_in_key}' );
      define( 'NONCE_KEY',       '${nonce_key}' );
      define( 'AUTH_SALT',       '${auth_salt}' );
      define( 'SECURE_AUTH_SALT','${secure_auth_salt}' );
      define( 'LOGGED_IN_SALT',  '${logged_in_salt}' );
      define( 'NONCE_SALT',      '${nonce_salt}' );
      $$table_prefix = 'wp_';
      define( 'WP_SITEURL', '${wp_url}' );
      define( 'WP_HOME',    '${wp_url}' );
      define( 'WP_DEBUG',   false );
      if ( ! defined( 'ABSPATH' ) ) {
          define( 'ABSPATH', __DIR__ . '/' );
      }
      require_once ABSPATH . 'wp-settings.php';

  # WP admin password — stored in a file to avoid shell-escaping issues.
  # base64-encoded by Terraform; decoded in runcmd.
  - path: /root/wp-admin.b64
    permissions: '0600'
    content: "${wp_admin_pass_b64}"

runcmd:
  # ── Apache ──────────────────────────────────────────────────────────────────
  - a2enmod rewrite
  - a2ensite wordpress.conf
  - a2dissite 000-default.conf
  - systemctl enable --now apache2

  # ── Wait for DBaaS to be reachable (up to 15 min) ──────────────────────────
  - |
    DB_HOST="${db_host}"
    echo "Waiting for MySQL at $DB_HOST:3306 ..."
    for i in $(seq 1 90); do
      (echo > /dev/tcp/$DB_HOST/3306) 2>/dev/null && { echo "MySQL ready after $((i * 10))s"; break; }
      [ "$i" = "90" ] && { echo "ERROR: MySQL did not become ready in 15 minutes"; exit 1; }
      sleep 10
    done

  # ── Download and deploy WordPress ───────────────────────────────────────────
  - wget -q https://wordpress.org/latest.tar.gz -O /tmp/wp.tar.gz
  - tar -xzf /tmp/wp.tar.gz -C /tmp/
  - rsync -a --delete /tmp/wordpress/ /var/www/html/
  - rm -f /var/www/html/index.html
  - rm -rf /tmp/wordpress /tmp/wp.tar.gz

  # Place the pre-rendered wp-config.php
  - cp /root/wp-config.php /var/www/html/wp-config.php

  # Set correct ownership and permissions
  - chown -R www-data:www-data /var/www/html
  - find /var/www/html -type d -exec chmod 755 {} \;
  - find /var/www/html -type f -exec chmod 644 {} \;
  - chmod 640 /var/www/html/wp-config.php

  # ── Install WP-CLI ──────────────────────────────────────────────────────────
  - curl -sL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp
  - chmod +x /usr/local/bin/wp

  # ── WordPress site installation ─────────────────────────────────────────────
  - |
    set -euo pipefail
    WP_ADMIN_PASS=$(base64 -d /root/wp-admin.b64)
    sudo -u www-data wp core install \
      --path=/var/www/html \
      --url="${wp_url}" \
      --title="${wp_title}" \
      --admin_user="${wp_admin_user}" \
      --admin_password="$WP_ADMIN_PASS" \
      --admin_email="${wp_admin_email}" \
      --skip-email
    rm -f /root/wp-admin.b64 /root/wp-config.php

  # ── Optional: HTTPS via Let's Encrypt ──────────────────────────────────────
  - |
    DOMAIN="${domain}"
    EAB_KID="${acme_eab_kid}"
    EAB_HMAC="${acme_eab_hmac_key}"
    if [ -n "$DOMAIN" ]; then
      CERTBOT_EAB=""
      if [ -n "$EAB_KID" ] && [ -n "$EAB_HMAC" ]; then
        CERTBOT_EAB="--server https://acme-api.actalis.com/acme/directory --eab-kid $EAB_KID --eab-hmac-key $EAB_HMAC"
      fi
      echo "Configuring HTTPS for $DOMAIN ..."
      certbot --apache \
        -d "$DOMAIN" \
        --non-interactive \
        --agree-tos \
        -m "${wp_admin_email}" \
        --redirect \
        $CERTBOT_EAB \
        && echo "HTTPS configured successfully." \
        || echo "WARNING: Certbot failed. Ensure DNS points to this IP and retry."
    fi

  - systemctl restart apache2

final_message: |
  WordPress bootstrap complete.
  Site: ${wp_url}
  Admin: ${wp_url}/wp-admin
  Logs: /var/log/cloud-init-output.log
