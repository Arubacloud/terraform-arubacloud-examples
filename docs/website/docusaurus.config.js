// @ts-check
// Note: type annotations allow type checking and IDEs autocompletion

const lightCodeTheme = require('prism-react-renderer').themes.github;
const darkCodeTheme = require('prism-react-renderer').themes.dracula;

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'ArubaCloud Terraform Examples',
  tagline: 'Production-ready Terraform examples for deploying open-source applications on Aruba Cloud',
  favicon: 'img/favicon.ico',

  url: 'https://arubacloud.github.io',
  baseUrl: '/terraform-arubacloud-examples/',

  organizationName: 'arubacloud',
  projectName: 'terraform-arubacloud-examples',
  trailingSlash: false,

  onBrokenLinks: 'throw',
  markdown: {
    mermaid: true,
    hooks: {
      onBrokenMarkdownLinks: 'warn',
    },
  },

  themes: ['@docusaurus/theme-mermaid'],

  i18n: {
    defaultLocale: 'en',
    locales: ['en', 'it'],
    localeConfigs: {
      en: {
        label: 'English',
        direction: 'ltr',
        htmlLang: 'en-US',
        calendar: 'gregory',
      },
      it: {
        label: 'Italiano',
        direction: 'ltr',
        htmlLang: 'it-IT',
        calendar: 'gregory',
      },
    },
  },

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          sidebarPath: require.resolve('./sidebars.js'),
          editUrl: 'https://github.com/arubacloud/terraform-arubacloud-examples/tree/main/docs/',
          routeBasePath: '/',
          path: 'docs',
          versions: process.env.DISABLE_VERSIONING === 'true' ? {} : {
            current: {
              label: 'Next',
              path: 'next',
            },
          },
          showLastUpdateTime: true,
          showLastUpdateAuthor: true,
        },
        blog: false,
        theme: {
          customCss: require.resolve('./src/css/custom.css'),
        },
      }),
    ],
  ],

  plugins: [
    [
      require.resolve('@easyops-cn/docusaurus-search-local'),
      {
        hashed: true,
        language: ['en', 'it'],
        highlightSearchTermsOnTargetPage: true,
        explicitSearchResultPath: true,
        indexBlog: false,
        indexPages: false,
        docsRouteBasePath: '/',
        removeDefaultStopWordFilter: false,
        removeDefaultStemmer: false,
      },
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      image: 'img/docusaurus-social-card.jpg',
      navbar: {
        title: 'Terraform Examples',
        logo: {
          alt: 'Aruba Cloud Terraform Examples Logo',
          src: 'img/logo-cloud.png',
          srcDark: 'img/logo-cloud.png',
          width: 32,
          height: 32,
          href: '/intro',
        },
        items: [
          {
            type: 'docSidebar',
            sidebarId: 'mainSidebar',
            position: 'left',
            label: 'Documentation',
          },
          {
            type: 'localeDropdown',
            position: 'right',
          },
          ...(process.env.DISABLE_VERSIONING !== 'true' ? [{
            type: 'docsVersionDropdown',
            position: 'right',
          }] : []),
          {
            href: 'https://github.com/arubacloud/terraform-arubacloud-examples',
            label: 'GitHub',
            position: 'right',
          },
        ],
      },
      footer: {
        style: 'dark',
        links: [
          {
            title: 'Documentation',
            items: [
              {
                label: 'Getting Started',
                to: process.env.DISABLE_VERSIONING === 'true'
                  ? '/getting-started'
                  : '/next/getting-started',
              },
              {
                label: 'Examples',
                to: process.env.DISABLE_VERSIONING === 'true'
                  ? '/examples/wordpress'
                  : '/next/examples/wordpress',
              },
            ],
          },
          {
            title: 'Community',
            items: [
              {
                label: 'GitHub',
                href: 'https://github.com/arubacloud/terraform-arubacloud-examples',
              },
              {
                label: 'Issues',
                href: 'https://github.com/arubacloud/terraform-arubacloud-examples/issues',
              },
            ],
          },
          {
            title: 'More',
            items: [
              {
                label: 'Aruba Cloud',
                href: 'https://www.arubacloud.com',
              },
              {
                label: 'Changelog',
                href: 'https://github.com/arubacloud/terraform-arubacloud-examples/releases',
              },
            ],
          },
        ],
        copyright: `Copyright © ${new Date().getFullYear()} Aruba S.p.A. - via San Clemente, 53 - 24036 Ponte San Pietro (BG) P.IVA 01573850516 - C.F. 04552920482 - C.S. € 4.000.000,00 i.v. - Numero REA: BG – 434483 - All rights reserved`,
      },
      prism: {
        theme: lightCodeTheme,
        darkTheme: darkCodeTheme,
        additionalLanguages: ['bash', 'hcl', 'yaml', 'powershell'],
      },
    }),
};

module.exports = config;
