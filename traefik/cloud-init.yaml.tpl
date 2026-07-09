#cloud-config
# Traefik v3 reverse proxy with automatic Let's Encrypt TLS.
# Deployed via Docker Compose.

package_update: true
package_upgrade: true
packages:
  - ca-certificates
  - curl
  - gnupg

write_files:
  - path: /opt/traefik/traefik.yml
    content: |
      api:
        dashboard: ${enable_dashboard}
        insecure: ${enable_dashboard}

      entryPoints:
        web:
          address: ":80"
          http:
            redirections:
              entryPoint:
                to: websecure
                scheme: https
        websecure:
          address: ":443"

      certificatesResolvers:
        letsencrypt:
          acme:
            email: ${acme_email}
            storage: /letsencrypt/acme.json
            httpChallenge:
              entryPoint: web

      providers:
        docker:
          exposedByDefault: false
        file:
          directory: /etc/traefik/dynamic
          watch: true

      log:
        level: INFO

      accessLog: {}

  - path: /opt/traefik/docker-compose.yml
    content: |
      services:
        traefik:
          image: traefik:${traefik_version}
          container_name: traefik
          restart: unless-stopped
          ports:
            - "80:80"
            - "443:443"
%{ if enable_dashboard ~}
            - "8080:8080"
%{ endif ~}
          volumes:
            - /var/run/docker.sock:/var/run/docker.sock:ro
            - /opt/traefik/traefik.yml:/traefik.yml:ro
            - /opt/traefik/dynamic:/etc/traefik/dynamic:ro
            - traefik_letsencrypt:/letsencrypt
          networks:
            - traefik-public

      networks:
        traefik-public:
          name: traefik-public
          driver: bridge

      volumes:
        traefik_letsencrypt:

  # Dynamic configuration directory for custom routers/middleware
  - path: /opt/traefik/dynamic/.gitkeep
    content: ""

runcmd:
  # Install Docker CE
  - install -m 0755 -d /etc/apt/keyrings
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  - chmod a+r /etc/apt/keyrings/docker.asc
  - |
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
    https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    > /etc/apt/sources.list.d/docker.list
  - apt-get update -y
  - apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  - usermod -aG docker ubuntu

  # Start Traefik
  - cd /opt/traefik && docker compose up -d

final_message: "Traefik is running. Dashboard: http://<IP>:8080 (if enabled)"
