---
title: Changelog
---

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Example versions follow a `MAJOR.MINOR.PATCH` scheme where MINOR increments on
each batch of new examples and PATCH on fixes.

## [Unreleased]

### Added

- **Wiki.js** (`wikijs/`) — Node.js wiki with Managed MySQL 8.0 DBaaS backend,
  Docker-based deployment, web UI on port 3000 (closes #24).
- **Nexus Repository OSS** (`nexus/`) — Universal artifact registry (Maven, npm,
  Docker, PyPI) via the official `sonatype/nexus3` Docker image, 100 GB persistent
  storage, optional Docker registry on port 8082 (closes #23).
- **CONTRIBUTING.md** — Quick-start contributor guide at repo root, linking to
  the full guide in `docs/contributing.md` (closes #4).
- **CODE_OF_CONDUCT.md** — Contributor Covenant 2.1 code of conduct (closes #4).
- **`.github/PULL_REQUEST_TEMPLATE.md`** — PR checklist for new examples and
  pre-submit checks (closes #4).
- **`.github/ISSUE_TEMPLATE/new-example.yml`** — Structured GitHub form for
  requesting new example additions (closes #4).
- **`.github/ISSUE_TEMPLATE/bug-report.yml`** — Structured GitHub form for
  reporting bugs in existing examples (closes #4).
- **`.github/dependabot.yml`** — Weekly Terraform provider version monitoring
  for all 48 directories (47 examples + `modules/network`) (closes #3).
- **`CHANGELOG.md`** — This file, at repo root, following Keep a Changelog.

## [0.4.0] - 2026-07-10

### Added

- **Discourse** (`discourse/`) — Docker-based forum platform with Sidekiq,
  PostgreSQL, and Redis; SMTP and admin email configuration (closes #38).
- **Rocket.Chat** (`rocketchat/`) — Docker Compose team chat with MongoDB;
  admin account pre-configured via environment variables (closes #39).
- **Elasticsearch** (`elasticsearch/`) — Single-node cluster via APT package,
  systemd service, JVM heap tuning, health-check in cloud-init (closes #36).
- **OpenSearch** (`opensearch/`) — Docker Compose single-node, password passed
  via `.env` file, `vm.max_map_count` kernel tuning (closes #34).
- **CrowdSec** (`crowdsec/`) — Native APT packages from packagecloud.io,
  `nftables` firewall bouncer, optional console enrollment via enroll key
  (closes #33).
- **Open WebUI** (`open-webui/`) — Docker + nginx reverse proxy on port 80,
  auto-generated secret key, optional Ollama and OpenAI integration (closes #29).
- **Ollama** (`ollama/`) — Official install script, systemd override to bind on
  all interfaces, optional model pre-pulling loop via template directive
  (closes #30).
- **LiteLLM** (`litellm/`) — Docker container with dynamically-built per-provider
  YAML configuration; supports OpenAI, Anthropic, and Ollama backends (closes #31).
- **OpenClaw** (`openclaw/`) — Docker + nginx on port 3000, optional OpenAI and
  Anthropic API key injection (closes #32).
- **Authentik** (`authentik/`) — Docker Compose stack: PostgreSQL 16 + Redis +
  Authentik server + worker; setup wizard on first access (closes #28).
- **Graylog** (`graylog/`) — Docker Compose: MongoDB 6 + OpenSearch 2 + Graylog;
  SHA-256 admin password hash, auto-generated internal OpenSearch password;
  ports 9000 (web), 1514 (syslog TCP), 12201 (GELF UDP) (closes #35).
- **Mailcow** (`mailcow/`) — Official `mailcow-dockerized` installer, all mail
  ports (25/465/587/993/995/4190) open, Let's Encrypt auto-TLS (closes #26).
- **GitLab CE** (`gitlab/`) — Omnibus package installer, optional Let's Encrypt
  auto-TLS, git SSH on port 2222 (closes #25).
- **k3s HA Cluster** (`k3s-ha/`) — Three control-plane nodes with per-node
  Elastic IPs, external MySQL 8.0 datastore via kine, `for_each` over node
  names (closes #27).
- New **AI/ML** nav section in `mkdocs.yml`: Ollama, Open WebUI, LiteLLM,
  OpenClaw.
- New `docs/examples/` stubs for all 13 new examples.

## [0.3.0] - 2026-07-10

### Added

- **Adminer** (`adminer/`) — Lightweight database web UI for MySQL/PostgreSQL
  (closes #42).
- **AdGuard Home** (`adguard-home/`) — DNS-level ad and tracker blocker
  (closes #44).
- **NGINX** (`nginx/`) — Reverse proxy and static file server (closes #47).
- **Caddy** (`caddy/`) — Automatic HTTPS reverse proxy via Caddyfile (closes #48).
- **pgAdmin** (`pgadmin/`) — Web UI for PostgreSQL administration (closes #43).
- **CoreDNS** (`coredns/`) — Lightweight, plugin-based DNS server (closes #46).
- **Drupal** (`drupal/`) — CMS with Managed MySQL 8.0 DBaaS (closes #52).
- **Joomla** (`joomla/`) — CMS with Managed MySQL 8.0 DBaaS (closes #53).
- **HAProxy** (`haproxy/`) — High-availability TCP/HTTP load balancer (closes #49).
- **Bind DNS** (`bind-dns/`) — Full-featured authoritative/recursive DNS server
  via named; zone configuration via template (closes #45).
- **Rundeck** (`rundeck/`) — Operations automation and runbook platform
  (closes #50).
- **Drone CI** (`drone-ci/`) — Container-native CI/CD pipeline server (closes #51).
- **Home Assistant** (`home-assistant/`) — Home automation platform with Docker
  deployment (closes #40).
- **Wazuh** (`wazuh/`) — Security monitoring: manager + dashboard + indexer via
  Docker Compose (closes #41).
- `ai/guardrails.md` — Pre-submit checklist documenting `terraform fmt`,
  `validate`, TFLint, and markdownlint rules.

### Fixed

- MD028 (blank line in blockquote) in Wazuh README.
- MD036 (emphasis as heading) and MD040 (fenced code language) in Rundeck README
  and guardrails documentation.
- HCL alignment in `pgadmin/main.tf`; CoreDNS README code block language tags.

## [0.2.0] - 2026-07-10

### Added

- **Jenkins LTS** (`jenkins/`) — CI/CD server via APT package, systemd service
  (closes #16).
- **Grafana + Prometheus + Loki** (`grafana/`) — Observability stack via Docker
  Compose (closes #17).
- **HashiCorp Vault** (`vault/`) — Secrets manager with file storage backend
  (closes #18).
- **Keycloak** (`keycloak/`) — IAM and SSO platform via Docker, Managed
  PostgreSQL DBaaS (closes #19).
- **Mattermost** (`mattermost/`) — Team messaging platform via Docker, Managed
  PostgreSQL DBaaS (closes #20).
- **SonarQube Community** (`sonarqube/`) — Static code analysis via Docker
  (closes #22).
- **Pi-hole** (`pi-hole/`) — Network-wide DNS ad blocker (closes #21).
- **k3s Single Node** (`k3s-single/`) — Lightweight Kubernetes via official
  install script (closes #15).
- **Gitea** (`gitea/`) — Self-hosted Git service, Managed MySQL DBaaS (closes #14).
- **Forgejo** (`forgejo/`) — Gitea fork, self-hosted Git service, Managed MySQL
  DBaaS (closes #13).
- **Ghost** (`ghost/`) — Node.js blogging platform via Docker (closes #37).
- `docs/examples/` stubs for all Phase 2 examples; mkdocs nav updated.

### Fixed

- Single-line HCL blocks expanded to multi-line in `traefik` and `nextcloud`
  to comply with `terraform fmt`.
- Missing `docs/examples/` stubs for Phase 1 examples; mkdocs nav gaps closed.
- `contributing.md` excluded from `include-markdown` plugin to prevent
  processing `{%` syntax in the contributing guide.

## [0.1.0] - 2026-07-09

### Added

- **Initial infrastructure** — `modules/network` shared module (VPC + subnet +
  security group + Elastic IP, optional DBaaS network); provider constraints
  `~> 0.5`; GitHub Actions CI (`terraform fmt`, `validate`, TFLint, markdownlint).
- **MkDocs Material** documentation site with nav, search, Mermaid diagram
  support, and `include-markdown` plugin.
- **WordPress** (`wordpress/`) — LAMP stack with Managed MySQL 8.0 DBaaS;
  reference example establishing all file and README conventions.
- **WireGuard** (`wireguard/`) — VPN server with kernel module and `wg-quick`
  systemd service (closes #6).
- **Docker Host** (`docker-host/`) — Docker CE single-VM host (closes #7).
- **Uptime Kuma** (`uptime-kuma/`) — Uptime monitoring dashboard via Docker
  (closes #8).
- **Vaultwarden** (`vaultwarden/`) — Bitwarden-compatible password manager via
  Docker (closes #9).
- **MinIO** (`minio/`) — S3-compatible object storage via Docker (closes #10).
- **Traefik** (`traefik/`) — Reverse proxy with automatic HTTPS via Let's Encrypt
  (closes #11).
- **Nextcloud** (`nextcloud/`) — File sync and collaboration with Managed MySQL
  8.0 DBaaS (closes #12).

[Unreleased]: https://github.com/Arubacloud/terraform-arubacloud-examples/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/Arubacloud/terraform-arubacloud-examples/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/Arubacloud/terraform-arubacloud-examples/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/Arubacloud/terraform-arubacloud-examples/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/Arubacloud/terraform-arubacloud-examples/releases/tag/v0.1.0

