// @ts-check

/** @type {import('@docusaurus/plugin-content-docs').SidebarsConfig} */
const sidebars = {
  mainSidebar: [
    {
      type: 'doc',
      id: 'intro',
      label: 'Introduction',
    },
    {
      type: 'doc',
      id: 'getting-started',
      label: 'Getting Started',
    },
    {
      type: 'category',
      label: 'Architecture & Best Practices',
      items: [
        'architecture',
        'best-practices',
        'security',
      ],
    },
    {
      type: 'category',
      label: 'Examples',
      items: [
        {
          type: 'category',
          label: 'CMS',
          items: [
            'examples/wordpress',
            'examples/nextcloud',
            'examples/ghost',
            'examples/drupal',
            'examples/joomla',
          ],
        },
        {
          type: 'category',
          label: 'DevOps',
          items: [
            'examples/gitea',
            'examples/forgejo',
            'examples/gitlab',
            'examples/jenkins',
            'examples/sonarqube',
            'examples/rundeck',
            'examples/drone-ci',
          ],
        },
        {
          type: 'category',
          label: 'Networking',
          items: [
            'examples/wireguard',
            'examples/traefik',
            'examples/pi-hole',
            'examples/adguard-home',
            'examples/nginx',
            'examples/caddy',
            'examples/coredns',
            'examples/haproxy',
            'examples/bind-dns',
          ],
        },
        {
          type: 'category',
          label: 'Database Admin',
          items: [
            'examples/adminer',
            'examples/pgadmin',
          ],
        },
        {
          type: 'category',
          label: 'Containers',
          items: [
            'examples/docker-host',
            'examples/k3s-single',
            'examples/k3s-ha',
          ],
        },
        {
          type: 'category',
          label: 'Storage',
          items: [
            'examples/minio',
          ],
        },
        {
          type: 'category',
          label: 'Identity',
          items: [
            'examples/keycloak',
            'examples/authentik',
            'examples/vault',
          ],
        },
        {
          type: 'category',
          label: 'Observability',
          items: [
            'examples/grafana-prometheus',
            'examples/uptime-kuma',
            'examples/elasticsearch',
            'examples/opensearch',
            'examples/graylog',
            'examples/wazuh',
          ],
        },
        {
          type: 'category',
          label: 'AI / ML',
          items: [
            'examples/ollama',
            'examples/open-webui',
            'examples/litellm',
            'examples/openclaw',
          ],
        },
        {
          type: 'category',
          label: 'Collaboration',
          items: [
            'examples/mattermost',
            'examples/mailcow',
            'examples/rocketchat',
            'examples/discourse',
          ],
        },
        {
          type: 'category',
          label: 'Security',
          items: [
            'examples/vaultwarden',
            'examples/crowdsec',
          ],
        },
        {
          type: 'category',
          label: 'Homelab',
          items: [
            'examples/home-assistant',
          ],
        },
      ],
    },
    {
      type: 'category',
      label: 'Modules',
      items: [
        'modules/network',
      ],
    },
    {
      type: 'category',
      label: 'Reference',
      items: [
        'faq',
        'contributing',
        'changelog',
      ],
    },
  ],
};

module.exports = sidebars;
