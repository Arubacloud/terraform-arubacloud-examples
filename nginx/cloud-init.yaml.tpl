#cloud-config
# NGINX web server bootstrap for Aruba Cloud.
# Installs NGINX from Ubuntu packages. Optionally configures HTTPS via Let's Encrypt.
# Rendered by Terraform templatefile() — do not use this file directly.

package_update: true
package_upgrade: true

packages:
  - nginx
  - certbot
  - python3-certbot-nginx

write_files:
  # Default site configuration
  - path: /etc/nginx/sites-available/default
    content: |
      server {
          listen 80 default_server;
          listen [::]:80 default_server;

          server_name ${domain != "" ? domain : "_"};
          root /var/www/html;
          index index.html;

          location / {
              try_files $$uri $$uri/ =404;
          }
      }

  # Default index page
  - path: /var/www/html/index.html
    owner: www-data:www-data
    content: |
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="utf-8">
        <title>NGINX on Aruba Cloud</title>
        <style>
          body { font-family: sans-serif; max-width: 600px; margin: 80px auto; color: #333; }
          h1   { color: #009900; }
          code { background: #f4f4f4; padding: 2px 6px; border-radius: 3px; }
        </style>
      </head>
      <body>
        <h1>NGINX is running</h1>
        <p>Your NGINX web server on Aruba Cloud is up.</p>
        <p>Replace <code>/var/www/html/index.html</code> with your own content,
           or drop site configs into <code>/etc/nginx/sites-available/</code>.</p>
      </body>
      </html>

runcmd:
  # ── Enable and start NGINX ────────────────────────────────────────────────────
  - nginx -t
  - systemctl enable nginx
  - systemctl start nginx

  # ── Optional HTTPS via Let's Encrypt ─────────────────────────────────────────
  - |
    DOMAIN="${domain}"
    EMAIL="${certbot_email}"
    if [ -n "$DOMAIN" ] && [ -n "$EMAIL" ]; then
      certbot --nginx \
        -d "$DOMAIN" \
        --non-interactive \
        --agree-tos \
        -m "$EMAIL" \
        --redirect \
        && echo "HTTPS configured successfully." \
        || echo "WARNING: Certbot failed. Ensure DNS A record points to this IP and retry."
    elif [ -n "$DOMAIN" ] && [ -z "$EMAIL" ]; then
      echo "WARNING: domain is set but certbot_email is empty — skipping Let's Encrypt."
    fi

  - nginx -t && systemctl reload nginx

final_message: |
  NGINX bootstrap complete.
  HTTP:  http://<IP>
  HTTPS: https://${domain != "" ? domain : "<not configured>"} (if domain and certbot_email were set)
  Web root: /var/www/html
  Logs: /var/log/nginx/access.log  /var/log/nginx/error.log
  cloud-init log: /var/log/cloud-init-output.log
