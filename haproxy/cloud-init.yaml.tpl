#cloud-config
# HAProxy load balancer bootstrap for Aruba Cloud.
# Installs HAProxy from Ubuntu packages with a preconfigured HTTP frontend,
# round-robin backend, and stats page on port 8404.
# When no backends are configured, a local nginx demo server on 127.0.0.1:8080
# is installed so the proxy returns a real response instead of 503.
# Rendered by Terraform templatefile() — do not use this file directly.

package_update: true
package_upgrade: true

packages:
  - haproxy
%{ if length(backends) == 0 ~}
  - nginx
%{ endif ~}

write_files:
%{ if length(backends) == 0 ~}
  - path: /etc/nginx/sites-available/haproxy-demo
    content: |
      server {
          listen 127.0.0.1:8080;
          server_name localhost;
          location / {
              return 200 'HAProxy demo backend\nThis response comes from a local nginx instance on 127.0.0.1:8080.\nAdd real backends via the backends Terraform variable.\n';
              add_header Content-Type text/plain;
          }
      }

%{ endif ~}
  - path: /etc/haproxy/haproxy.cfg
    content: |
      global
          log /dev/log local0
          log /dev/log local1 notice
          maxconn 50000
          user haproxy
          group haproxy
          daemon

      defaults
          log     global
          mode    http
          option  httplog
          option  dontlognull
          option  forwardfor
          option  http-server-close
          timeout connect 5s
          timeout client  50s
          timeout server  50s

      frontend http_in
          bind *:80
          default_backend web_servers

      backend web_servers
          balance roundrobin
          option httpchk GET /
%{ for i, backend in backends ~}
          server web${i + 1} ${backend} check
%{ endfor ~}
%{ if length(backends) == 0 ~}
          server demo-local 127.0.0.1:8080 check
%{ endif ~}

      frontend stats
          bind *:8404
          stats enable
          stats uri /stats
          stats refresh 10s
          stats auth admin:${stats_password}
          stats hide-version
          stats show-node

runcmd:
%{ if length(backends) == 0 ~}
  - ln -sf /etc/nginx/sites-available/haproxy-demo /etc/nginx/sites-enabled/haproxy-demo
  - rm -f /etc/nginx/sites-enabled/default
  - nginx -t
  - systemctl enable nginx
  - systemctl restart nginx
%{ endif ~}
  - haproxy -c -f /etc/haproxy/haproxy.cfg
  - systemctl enable haproxy
  - systemctl restart haproxy

final_message: |
  HAProxy bootstrap complete.
  Proxy:  http://<IP>:80
  Stats:  http://<IP>:8404/stats  (login: admin / your stats_password)
  Config: /etc/haproxy/haproxy.cfg
  Logs:   journalctl -u haproxy -f
  cloud-init log: /var/log/cloud-init-output.log
