import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  docsSidebar: [
    {
      type: 'doc',
      id: '00-intro',
      label: '소개',
    },
    {
      type: 'category',
      label: '시스템 설계',
      items: [
        '01-system-overview',
        '02-system-architecture',
        '03-contract-structure',
        '04-contract-roles',
      ],
    },
    {
      type: 'category',
      label: '액터 및 함수',
      items: [
        '05-actors',
        '06-function-specs',
      ],
    },
    {
      type: 'category',
      label: '가이드',
      items: [
        '07-economics-whitepaper-summary',
        '08-v2-to-v3-upgrade-guide',
        '09-layer2-registration-guide',
      ],
    },
    {
      type: 'category',
      label: '테스트 및 운영',
      items: [
        '10-v3-test-lists',
        '11-seigniorage-update-cases',
      ],
    },
    {
      type: 'category',
      label: '통합',
      items: [
        '12-optimism-integration',
      ],
    },
  ],
};

export default sidebars;
