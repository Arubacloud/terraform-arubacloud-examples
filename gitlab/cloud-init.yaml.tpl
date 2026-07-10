#cloud-config
# GitLab CE for Aruba Cloud.
# Uses the official Omnibus package installer.
# Rendered by Terraform templatefile() — do not use this file directly.
#
# With an HTTPS external_url and valid DNS, Let's Encrypt is provisioned automatically.
# Bootstrap takes 5-10 minutes.

package_update: true
package_upgrade: true

packages:
  - ca-certificates
  - curl
  - openssh-server
  - tzdata
  - perl

write_files:
  - path: /root/gitlab-root.b64
    permissions: "0600"
    content: "${root_pass_b64}"

runcmd:
  # ── Add GitLab CE package repository ─────────────────────────────────────────
  - curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | bash

  # ── Install GitLab CE ─────────────────────────────────────────────────────────
  - |
    ROOT_PASS=$(base64 -d /root/gitlab-root.b64)
    rm -f /root/gitlab-root.b64
    GITLAB_ROOT_PASSWORD="$ROOT_PASS" \
      EXTERNAL_URL="${external_url}" \
      apt-get install -y gitlab-ce

  # ── Set Let's Encrypt contact email if provided ───────────────────────────────
  - |
    if [ -n "${letsencrypt_email}" ]; then
      grep -q "letsencrypt\['contact_emails'\]" /etc/gitlab/gitlab.rb || \
        printf "\nletsencrypt['contact_emails'] = ['${letsencrypt_email}']\n" \
          >> /etc/gitlab/gitlab.rb
      gitlab-ctl reconfigure
    fi

final_message: |
  GitLab CE bootstrap complete (may take 5-10 minutes if Let's Encrypt is enabled).
  Web UI:    ${external_url}
  Login:     root / <gitlab_root_password>
  SSH clone: git clone ssh://git@${gitlab_hostname}:2222/<user>/<project>.git
  Logs:      journalctl -u gitlab-runsvdir -f
  cloud-init log: /var/log/cloud-init-output.log
