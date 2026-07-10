#cloud-config
# pgAdmin 4 bootstrap for Aruba Cloud.
# Installs pgAdmin 4 (web mode) from the official pgAdmin apt repository.
# Apache is configured automatically by the pgAdmin setup script.
# Rendered by Terraform templatefile() — do not use this file directly.

package_update: true
package_upgrade: true

packages:
  - curl
  - gnupg

write_files:
  # Admin password stored base64-encoded to avoid shell special-character issues
  - path: /root/pgadmin-pass.b64
    permissions: "0600"
    content: "${pgadmin_pass_b64}"

runcmd:
  # ── Add pgAdmin apt repository ────────────────────────────────────────────────
  - |
    curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub \
      | gpg --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg
    echo "deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" \
      > /etc/apt/sources.list.d/pgadmin4.list
    apt-get update -qq
    apt-get install -y pgadmin4-web

  # ── Configure pgAdmin non-interactively ──────────────────────────────────────
  - |
    PGADMIN_PASS=$(base64 -d /root/pgadmin-pass.b64)
    rm -f /root/pgadmin-pass.b64
    PGADMIN_SETUP_EMAIL="${pgadmin_email}" \
    PGADMIN_SETUP_PASSWORD="$PGADMIN_PASS" \
      /usr/pgadmin4/bin/setup-web.sh --yes

final_message: |
  pgAdmin 4 bootstrap complete.
  URL:   http://<IP>/pgadmin4  (accessible from admin_cidr only)
  Login: ${pgadmin_email}
  pgAdmin takes 1-2 minutes to initialise after cloud-init completes.
  Logs: /var/log/cloud-init-output.log
  Apache logs: /var/log/apache2/error.log
