#cloud-config
# Docker CE host bootstrap for Aruba Cloud.
# Installs Docker Engine + Docker Compose plugin from the official Docker APT repo.

package_update: true
package_upgrade: true
packages:
  - ca-certificates
  - curl
  - gnupg

runcmd:
  # Add Docker's official GPG key and APT repository
  - install -m 0755 -d /etc/apt/keyrings
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  - chmod a+r /etc/apt/keyrings/docker.asc
  - |
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
      https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
      > /etc/apt/sources.list.d/docker.list
  - apt-get update -y
  - apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # Add ubuntu (and any additional users) to the docker group
  - usermod -aG docker ubuntu
%{ for user in docker_users ~}
  - usermod -aG docker ${user}
%{ endfor ~}

  # Enable and start Docker
  - systemctl enable docker
  - systemctl start docker

  # Verify installation
  - docker --version
  - docker compose version

final_message: "Docker host ready. Reconnect SSH for docker group membership to take effect."
