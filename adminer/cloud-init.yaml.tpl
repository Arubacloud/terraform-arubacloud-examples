#cloud-config
# Adminer database admin tool bootstrap for Aruba Cloud.
# Apache2 + PHP 8.1 + Adminer single-file PHP application.
# Rendered by Terraform templatefile() — do not use this file directly.

package_update: true
package_upgrade: true

packages:
  - apache2
  - php
  - php-mysql
  - php-pgsql
  - php-sqlite3
  - curl

runcmd:
  # ── Download Adminer ──────────────────────────────────────────────────────────
  - |
    ADMINER_VERSION="${adminer_version}"
    curl -sSfL \
      "https://github.com/vrana/adminer/releases/download/v$ADMINER_VERSION/adminer-$ADMINER_VERSION.php" \
      -o /var/www/html/adminer.php
    chown www-data:www-data /var/www/html/adminer.php

  # ── Remove default Apache welcome page ───────────────────────────────────────
  - rm -f /var/www/html/index.html

  # ── Ensure Apache is enabled and running ─────────────────────────────────────
  - systemctl enable apache2
  - systemctl restart apache2

final_message: |
  Adminer bootstrap complete.
  URL: http://<IP>/adminer.php  (accessible from admin_cidr only)
  Enter your database server address, credentials, and database name to connect.
  Supported: MySQL/MariaDB, PostgreSQL, SQLite.
  Logs: /var/log/cloud-init-output.log
