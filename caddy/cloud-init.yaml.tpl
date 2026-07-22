#cloud-config
# Caddy web server bootstrap for Aruba Cloud.
# Installs Caddy from the official apt repository. Automatic HTTPS is enabled
# when a domain is configured — no certbot needed, Caddy handles it natively.
# Rendered by Terraform templatefile() — do not use this file directly.

package_update: true
package_upgrade: true

packages:
  - debian-keyring
  - debian-archive-keyring
  - apt-transport-https
  - curl

write_files:
  # Caddyfile — serves static files; automatic HTTPS when domain is set
  - path: /etc/caddy/Caddyfile
    content: |
%{ if acme_eab_kid != "" ~}
      {
        acme_ca https://acme-api.actalis.com/acme/directory
        acme_eab {
          key_id ${acme_eab_kid}
          mac_key ${acme_eab_hmac_key}
        }
      }

%{ endif ~}
      ${domain != "" ? domain : ":80"} {
          root * /var/www/html
          file_server
          encode gzip
          log
      }

  # Default index page
  - path: /var/www/html/index.html
    content: |
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="utf-8">
        <title>Caddy on Aruba Cloud</title>
        <style>
          body { font-family: sans-serif; max-width: 600px; margin: 80px auto; color: #333; }
          h1   { color: #00adef; }
          code { background: #f4f4f4; padding: 2px 6px; border-radius: 3px; }
        </style>
      </head>
      <body>
        <h1>Caddy is running</h1>
        <p>Your Caddy web server on Aruba Cloud is up.</p>
        <p>Replace <code>/var/www/html/index.html</code> with your own content,
           or edit <code>/etc/caddy/Caddyfile</code> to add sites and directives.</p>
      </body>
      </html>

runcmd:
  # ── Add Caddy official apt repository ────────────────────────────────────────
  - |
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
      | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
      | tee /etc/apt/sources.list.d/caddy-stable.list
    apt-get update -qq
    apt-get install -y caddy

  # ── Set web root ownership and reload Caddy ───────────────────────────────────
  - chown -R caddy:caddy /var/www/html
  - systemctl enable caddy
  - systemctl reload-or-restart caddy

final_message: |
  Caddy bootstrap complete.
  HTTP:  http://<IP>
  HTTPS: https://${domain != "" ? domain : "<not configured — set the domain variable>"}
  Web root:  /var/www/html
  Caddyfile: /etc/caddy/Caddyfile
  Logs: journalctl -u caddy -f
  cloud-init log: /var/log/cloud-init-output.log
