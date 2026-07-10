#cloud-config
# CrowdSec agent bootstrap for Aruba Cloud.
# Installs CrowdSec from the official apt repository, installs the specified
# collections, and optionally enrolls the instance with the CrowdSec Console.
# Rendered by Terraform templatefile() — do not use this file directly.

package_update: true
package_upgrade: true

packages:
  - curl
  - gnupg

runcmd:
  # ── Install CrowdSec from official apt repository ─────────────────────────────
  - |
    curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.deb.sh \
      | bash
    apt-get install -y crowdsec

  # ── Install collections ───────────────────────────────────────────────────────
%{ for col in collections ~}
  - cscli collections install ${col}
%{ endfor ~}

  # ── Reload CrowdSec to pick up new parsers/scenarios ─────────────────────────
  - systemctl reload crowdsec

  # ── Install the firewall bouncer (nftables) ───────────────────────────────────
  - apt-get install -y crowdsec-firewall-bouncer-nftables
  - systemctl enable --now crowdsec-firewall-bouncer

  # ── Optional: enroll with CrowdSec Console ───────────────────────────────────
  - |
    ENROLL_KEY="${enroll_key}"
    if [ -n "$ENROLL_KEY" ]; then
      cscli console enroll "$ENROLL_KEY"
      systemctl reload crowdsec
      echo "Enrolled with CrowdSec Console."
    else
      echo "No enroll_key provided — skipping Console enrollment."
    fi

final_message: |
  CrowdSec bootstrap complete.
  Agent status: sudo cscli version
  Active decisions: sudo cscli decisions list
  Collections: sudo cscli collections list
  Metrics: sudo cscli metrics
  Logs: journalctl -u crowdsec -f
  cloud-init log: /var/log/cloud-init-output.log
