#cloud-config
# HAProxy load balancer bootstrap for Aruba Cloud.
# Installs HAProxy from Ubuntu packages with a preconfigured HTTP frontend,
# round-robin backend, and stats page on port 8404.
# Rendered by Terraform templatefile() — do not use this file directly.

package_update: true
package_upgrade: true

packages:
  - haproxy

write_files:
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
          # No backends configured — HAProxy returns 503.
          # Add servers above or set the backends variable in terraform.tfvars.
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
