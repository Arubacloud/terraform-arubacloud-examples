#cloud-config
# MinIO single-node object storage bootstrap for Aruba Cloud.

package_update: true
package_upgrade: true
packages:
  - curl
  - wget

write_files:
  - path: /etc/default/minio
    permissions: '0640'
    content: |
      # MinIO environment — sourced by the systemd service
      MINIO_ROOT_USER="${minio_root_user}"
      MINIO_ROOT_PASSWORD="${minio_root_password}"
      MINIO_VOLUMES="${minio_data_dir}"
      MINIO_OPTS="--console-address :9001"

  - path: /etc/systemd/system/minio.service
    content: |
      [Unit]
      Description=MinIO Object Storage
      Documentation=https://min.io/docs/minio/linux/index.html
      Wants=network-online.target
      After=network-online.target
      AssertFileIsExecutable=/usr/local/bin/minio

      [Service]
      User=minio-user
      Group=minio-user
      EnvironmentFile=/etc/default/minio
      ExecStartPre=/bin/bash -c 'if [ -z "$${MINIO_VOLUMES}" ]; then echo "MINIO_VOLUMES not set"; exit 1; fi'
      ExecStart=/usr/local/bin/minio server $MINIO_OPTS $MINIO_VOLUMES
      Restart=always
      RestartSec=5
      LimitNOFILE=65536
      TasksMax=infinity
      TimeoutStopSec=120

      [Install]
      WantedBy=multi-user.target

runcmd:
  # Download MinIO binary
  - wget -q https://dl.min.io/server/minio/release/linux-amd64/minio -O /usr/local/bin/minio
  - chmod +x /usr/local/bin/minio

  # Create dedicated service user and data directory
  - useradd -r -s /usr/sbin/nologin minio-user
  - mkdir -p "${minio_data_dir}"
  - chown -R minio-user:minio-user "${minio_data_dir}"
  - chmod 750 "${minio_data_dir}"

  # Secure the environment file
  - chgrp minio-user /etc/default/minio

  # Enable and start MinIO
  - systemctl daemon-reload
  - systemctl enable --now minio

  - echo "MinIO S3 API: http://$(curl -s ifconfig.me):9000"
  - echo "MinIO Console: http://$(curl -s ifconfig.me):9001"

final_message: "MinIO is running. API: port 9000 | Console: port 9001"
