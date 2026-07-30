# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Example versions follow a `MAJOR.MINOR.PATCH` scheme where MINOR increments on
each batch of new examples and PATCH on fixes.

## [Unreleased]

## [0.5.5] - 2026-07-30

### Changed

- **All examples** — provider version constraint updated from `~> 0.5` to `~> 1.0`
  in every `versions.tf`, `README.md`, and documentation page; minimum supported
  provider is now `arubacloud/arubacloud >= 1.0.0`.

### Documentation

- **Getting Started** — prerequisites table updated to show minimum provider
  version 1.0 (was 0.5).
- **Best Practices** — pessimistic constraint example updated to `~> 1.0`.
- **All example READMEs** — provider version badge updated to `~> 1.0`.
- **Docusaurus website** — all current-version example and guide pages updated
  to reflect the new constraint; versioned snapshots (0.5.x) left intact.

## [0.5.4] - 2026-07-29

### Fixed

- **Wazuh** — retired `packages.wazuh.com/4.x` URL replaced with `wazuh_version`
  variable (default `4.9`) and `curl -f` to surface HTTP errors.
- **WordPress** — `table_prefix` in `wp-config.php`; `set -euo pipefail` replaced
  with `set -eu` for dash compatibility; raw `db_password` used after provider v1.0.1
  base64 fix.
- **Rundeck** — apt repository switched from `packagecloud.io` to
  `packages.rundeck.com` with `any/any` distro path.
- **SonarQube** — heredoc replaced with `printf` to fix cloud-init YAML parse
  failure.
- **Rocket.Chat** — `rs.initiate()` uses Docker service name `mongo:27017` instead
  of `localhost:27017`.
- **OpenClaw** — gateway bootstrap sequence, authentication, and nginx proxy port
  all fixed.
- **Nextcloud** — migrated to PHP 8.2 (added Ondřej PPA, pinned packages, switched
  Apache module from `php8.1` to `php8.2`).
- **MinIO** — download retry with binary integrity check; IP detection fallback
  fixed; schema validation error resolved.
- **LiteLLM** — empty model list bootstrap fixed; `entrypoint` argument passing
  corrected.
- **Keycloak** — build option and hostname URL updated for Keycloak 26.x.
- **k3s Single Node** — bash script moved to `write_files` to fix `pipefail` on
  dash.

### Removed

- **Open WebUI** (`open-webui/`) — incomplete example removed until a working
  version is ready.

### Documentation

- **CHANGELOG** backfilled with accurate per-release entries for v0.5.0–v0.5.3,
  including all compare links to GitHub tags.
- **Docusaurus** — Wiki.js and Nexus Repository example pages added in English
  and Italian; version 0.5.3 snapshot committed; version dropdown enabled.
- **CI** — `docs-release` workflow updated to accumulate the last 5 versioned doc
  snapshots and open a PR for each release (aligned with sdk-go).

## [0.5.3] - 2026-07-28

### Added

- **HAProxy** (`haproxy/`) — demo nginx backend auto-deployed when no external
  backends are configured; simplifies day-one testing without a real backend pool.
- **k3s HA** (`k3s-ha/`) — optional Managed MySQL 8.0 DBaaS as external etcd
  datastore; TLS SANs fixed.
- **Discourse** (`discourse/`) — optional `dev_smtp` mode with Mailpit container
  for local SMTP testing without an external mail server.

### Fixed

- **Jenkins** — APT keyring migrated to `/etc/apt/keyrings/` with the 2026 signing
  key; GPG dearmoring corrected; `runcmd` shell switched to bash for `pipefail`
  compatibility; repo setup moved to a `write_files` script.
- **GitLab CE** — `gitlab_hostname` made a required variable; plan-time validation
  added to reject placeholder values.
- **Ghost** — Node.js upgraded to 22; nginx `${}` variable escaping fixed; MySQL
  wait loop replaced with python3 socket; `ghost install` runs as the `ubuntu` user.
- **Grafana / Prometheus / Loki** — Loki startup fixed; Promtail journal access
  corrected; package install moved to `runcmd` to avoid dpkg races; nginx `${}`
  variable escaping corrected.
- **Discourse** — Docker MTU set to 1300 for Aruba Cloud network compatibility;
  `app_name` default shortened to satisfy the 8-character API minimum.
- **Elasticsearch** — `path.data` and `path.logs` added to config to prevent startup
  failure; password reset switched from `-p` flag to REST API.
- **Drupal** — cloud-init YAML parse error from multi-line Python block scalar fixed;
  additional bootstrap failures resolved.
- **CrowdSec** — full `cscli` path used to work around `sudo` `secure_path`.
- **Caddy** — dpkg conffile prompt suppressed during install.
- **AdGuard Home** — schema updated to `schema_version: 28`; `bind_host` field
  name corrected.
- **Forgejo** — `write_files` owner set to `root:root`; nginx `${}` variable
  escaping fixed.
- **Gitea** — `app.ini` written as `root:root` in `write_files`; ownership
  corrected in `runcmd`.
- **Graylog** — admin secret length, MongoDB service name and version, OpenSearch
  TLS, and Elasticsearch version pin all fixed from live-deploy test.
- **Adminer** — missing database and grant resources added; `db_password` correctly
  base64-encoded when passed to the DBaaS user resource.
- **Cloud-init (shared)** — nginx/PHP `${}` variable escaping corrected in
  `write_files` blocks; Python heredocs moved to `write_files` to avoid YAML parse
  failures; `/dev/tcp` MySQL wait-loops replaced with python3 socket calls; all
  resource tag values shorter than 4 characters expanded to meet API minimum.

## [0.5.2] - 2026-07-22

### Fixed

- **CI** — `github-pages` environment declaration added to the docs-release deploy
  job; without it the Pages API returned 400 regardless of permissions.
- **Default credentials** — `ssh_public_key` changed from an empty string to a
  valid RSA key; placeholder passwords replaced with API-compliant values across
  all 47 examples.

## [0.5.1] - 2026-07-22

### Fixed

- **CI** — pages concurrency group added to the docs-release workflow to prevent
  a race condition when a release event and a branch push trigger simultaneous
  GitHub Pages uploads.

## [0.5.0] - 2026-07-22

### Added

- **Wiki.js** (`wikijs/`) — Node.js wiki with Managed MySQL 8.0 DBaaS backend,
  Docker-based deployment, web UI on port 3000 (closes #24).
- **Nexus Repository OSS** (`nexus/`) — Universal artifact registry (Maven, npm,
  Docker, PyPI) via the official `sonatype/nexus3` Docker image, 100 GB persistent
  storage, optional Docker registry on port 8082 (closes #23).
- **Italian documentation** — full `it` locale for all 47 example pages and all
  editorial docs in the Docusaurus site.
- **Actalis ACME (EAB) support** — all SSL/HTTPS examples now expose optional
  `actalis_eab_kid` / `actalis_eab_hmac` variables for Italian CA certificates
  via Let's Encrypt EAB.
- **Defaults for all variables** — every module ships with sensible defaults so
  only `arubacloud_client_id` and `arubacloud_client_secret` are required to
  plan/apply.
- **Adminer** (`adminer/`) — now connects to a Managed MySQL DBaaS instead of a
  local database.
- **CONTRIBUTING.md** — quick-start contributor guide at repo root (closes #4).
- **CODE_OF_CONDUCT.md** — Contributor Covenant 2.1 code of conduct (closes #4).
- **`.github/PULL_REQUEST_TEMPLATE.md`** — PR checklist for new examples (closes #4).
- **`.github/ISSUE_TEMPLATE/new-example.yml`** and **`bug-report.yml`** —
  structured GitHub forms (closes #4).
- **`.github/dependabot.yml`** — weekly Terraform provider version monitoring for
  all 48 directories (closes #3).
- **`CHANGELOG.md`** — this file, following Keep a Changelog.

### Changed

- Provider version constraint bumped to `~> 1.0` across all examples (from `~> 1.0`).

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
- New **AI/ML** nav section in `mkdocs.yml`: Ollama, LiteLLM, OpenClaw.
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
  `~> 1.0`; GitHub Actions CI (`terraform fmt`, `validate`, TFLint, markdownlint).
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

[Unreleased]: https://github.com/Arubacloud/terraform-arubacloud-examples/compare/v0.5.4...HEAD
[0.5.4]: https://github.com/Arubacloud/terraform-arubacloud-examples/compare/v0.5.3...v0.5.4
[0.5.3]: https://github.com/Arubacloud/terraform-arubacloud-examples/compare/v0.5.2...v0.5.3
[0.5.2]: https://github.com/Arubacloud/terraform-arubacloud-examples/compare/v0.5.1...v0.5.2
[0.5.1]: https://github.com/Arubacloud/terraform-arubacloud-examples/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/Arubacloud/terraform-arubacloud-examples/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/Arubacloud/terraform-arubacloud-examples/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/Arubacloud/terraform-arubacloud-examples/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/Arubacloud/terraform-arubacloud-examples/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/Arubacloud/terraform-arubacloud-examples/releases/tag/v0.1.0
