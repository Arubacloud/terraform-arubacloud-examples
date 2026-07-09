#cloud-config
# Nextcloud bootstrap for Aruba Cloud.
# Apache 2.4 + PHP 8.1 + Redis + Managed MySQL DBaaS.

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
  - php-redis
  - php-apcu
  - redis-server
  - mysql-client
  - curl
  - wget
  - unzip
  - certbot
  - python3-certbot-apache
  - sudo

write_files:
  - path: /etc/apache2/sites-available/nextcloud.conf
    content: |
      <VirtualHost *:80>
          DocumentRoot /var/www/nextcloud
          <Directory /var/www/nextcloud/>
              Require all granted
              AllowOverride All
              Options FollowSymLinks MultiViews
          </Directory>
          <IfModule mod_dav.c>
              Dav off
          </IfModule>
          ErrorLog /var/log/apache2/nextcloud-error.log
          CustomLog /var/log/apache2/nextcloud-access.log combined
      </VirtualHost>

  # Nextcloud config.php — written before occ install
  - path: /var/www/nextcloud/config/config.php
    permissions: '0640'
    content: |
      <?php
      $CONFIG = array (
        'trusted_domains' => array('${domain != "" ? domain : "0.0.0.0"}'),
        'memcache.local'  => '\\OC\\Memcache\\APCu',
        'memcache.locking' => '\\OC\\Memcache\\Redis',
        'redis' => array(
          'host' => '127.0.0.1',
          'port' => 6379,
        ),
        'overwrite.cli.url' => '${site_url}',
        'default_language'  => 'en',
        'default_locale'    => 'en_US',
        'secret'            => '${nc_secret}',
      );

  # Admin password stored base64-encoded for safe shell handling
  - path: /root/nc-admin.b64
    permissions: '0600'
    content: "${nc_admin_password_b64}"

runcmd:
  # Enable PHP and Apache modules
  - a2enmod rewrite headers env dir mime setenvif
  - a2ensite nextcloud.conf
  - a2dissite 000-default.conf

  # Enable Redis
  - systemctl enable --now redis-server

  # Enable and start Apache
  - systemctl enable --now apache2

  # Wait for DBaaS (up to 15 minutes)
  - |
    DB_HOST="${db_host}"
    echo "Waiting for MySQL at $DB_HOST:3306 ..."
    for i in $(seq 1 90); do
      (echo > /dev/tcp/$DB_HOST/3306) 2>/dev/null && { echo "MySQL ready"; break; }
      [ "$i" = "90" ] && { echo "ERROR: MySQL timeout"; exit 1; }
      sleep 10
    done

  # Download Nextcloud
  - wget -q https://download.nextcloud.com/server/releases/latest.zip -O /tmp/nextcloud.zip
  - unzip -q /tmp/nextcloud.zip -d /var/www/
  - rm -f /tmp/nextcloud.zip
  - mkdir -p /var/www/nextcloud/data
  - chown -R www-data:www-data /var/www/nextcloud

  # Move our pre-written config.php into place (occ install will merge it)
  - chown www-data:www-data /var/www/nextcloud/config/config.php
  - chmod 640 /var/www/nextcloud/config/config.php

  # Run Nextcloud CLI installer
  - |
    set -euo pipefail
    NC_ADMIN_PASS=$(base64 -d /root/nc-admin.b64)
    sudo -u www-data php /var/www/nextcloud/occ maintenance:install \
      --database mysql \
      --database-host "${db_host}" \
      --database-name "${db_name}" \
      --database-user "${db_user}" \
      --database-pass "'${db_password_php}'" \
      --admin-user  "${nc_admin_user}" \
      --admin-pass  "$NC_ADMIN_PASS" \
      --data-dir /var/www/nextcloud/data
    rm -f /root/nc-admin.b64

  # Add trusted domain if not already configured
  - sudo -u www-data php /var/www/nextcloud/occ config:system:set trusted_domains 0 --value="${domain != "" ? domain : module_network_vm_elastic_ip}"

  # Optional HTTPS via Certbot
  - |
    DOMAIN="${domain}"
    if [ -n "$DOMAIN" ]; then
      certbot --apache -d "$DOMAIN" \
        --non-interactive --agree-tos \
        -m "${nc_admin_email}" \
        --redirect \
        && echo "HTTPS ready for $DOMAIN" \
        || echo "WARNING: Certbot failed"
    fi

  - systemctl reload apache2

final_message: "Nextcloud installation complete. URL: ${site_url}"
