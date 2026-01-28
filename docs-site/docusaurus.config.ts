import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const config: Config = {
  title: 'TON Staking V3',
  tagline: 'Tokamak Network Staking Documentation',
  favicon: 'img/favicon.ico',

  future: {
    v4: true,
  },

  // GitHub Pages 배포 설정
  url: process.env.DEPLOY_URL || 'http://localhost:3000',
  baseUrl: process.env.BASE_URL || '/',

  organizationName: 'tokamak-network',
  projectName: 'ton-staking-v2',
  trailingSlash: false,

  onBrokenLinks: 'warn',
  onBrokenMarkdownLinks: 'warn',

  // 다국어 설정 (한국어/영어)
  i18n: {
    defaultLocale: 'en',
    locales: ['en', 'ko'],
    localeConfigs: {
      en: {
        label: 'English',
        htmlLang: 'en-US',
      },
      ko: {
        label: '한국어',
        htmlLang: 'ko-KR',
      },
    },
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          editUrl: 'https://github.com/tokamak-network/ton-staking-v2/tree/ton-staking-v3/dev/docs-site/',
        },
        blog: false, // 블로그 비활성화
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    image: 'img/docusaurus-social-card.jpg',
    colorMode: {
      respectPrefersColorScheme: true,
    },
    navbar: {
      title: 'TON Staking V3',
      logo: {
        alt: 'Tokamak Network Logo',
        src: 'img/logo.svg',
      },
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'docsSidebar',
          position: 'left',
          label: 'Documentation',
        },
        {
          type: 'localeDropdown',
          position: 'right',
        },
        {
          href: 'https://github.com/tokamak-network/ton-staking-v2',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Docs',
          items: [
            {
              label: 'Architecture',
              to: '/docs/01_v2_architecture',
            },
            {
              label: 'Validator',
              to: '/docs/04_validator',
            },
          ],
        },
        {
          title: 'Community',
          items: [
            {
              label: 'Discord',
              href: 'https://discord.gg/tokamak',
            },
            {
              label: 'Twitter',
              href: 'https://twitter.com/tokaborneamak',
            },
          ],
        },
        {
          title: 'More',
          items: [
            {
              label: 'GitHub',
              href: 'https://github.com/tokamak-network/ton-staking-v2',
            },
            {
              label: 'Tokamak Network',
              href: 'https://tokamak.network',
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} Tokamak Network. Built with Docusaurus.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['solidity'],
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
