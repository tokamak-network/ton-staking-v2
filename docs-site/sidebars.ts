import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  docsSidebar: [
    {
      type: 'doc',
      id: '00-intro',
      label: 'Introduction',
    },
    {
      type: 'category',
      label: 'System Design',
      items: [
        '01-system-overview',
        '02-system-architecture',
        '03-contract-structure',
        '04-contract-roles',
      ],
    },
    {
      type: 'category',
      label: 'Actors',
      link: {
        type: 'generated-index',
        description: 'Learn about the different actors in the TON Staking V3 system.',
      },
      items: [
        'actors/actors-overview',
        'actors/actors-staker',
        'actors/actors-sequencer',
        'actors/actors-validator',
        'actors/actors-challenger',
        'actors/actors-dao',
        'actors/actors-l2-proposer',
      ],
    },
    {
      type: 'category',
      label: 'Function Specs',
      link: {
        type: 'doc',
        id: 'functions/functions-overview',
      },
      items: [
        'functions/functions-seig-manager',
        'functions/functions-deposit-manager',
        'functions/functions-layer2-manager',
        'functions/functions-l1-bridge-registry',
        'functions/functions-rat',
        'functions/functions-validator-reward',
        'functions/functions-sequencer-slashing',
        'functions/functions-operator-manager-factory',
        'functions/functions-governance-parameters',
        'functions/functions-events',
      ],
    },
    {
      type: 'category',
      label: 'Guides',
      items: [
        '07-economics-whitepaper-summary',
        {
          type: 'category',
          label: 'V2 → V3 Upgrade Guide',
          link: {
            type: 'doc',
            id: 'upgrade-guide/upgrade-overview',
          },
          items: [
            'upgrade-guide/upgrade-staker-guide',
            'upgrade-guide/upgrade-sequencer-guide',
            'upgrade-guide/upgrade-validator-guide',
            'upgrade-guide/upgrade-technical-details',
            'upgrade-guide/upgrade-migration-checklist',
            'upgrade-guide/upgrade-faq',
          ],
        },
        '09-layer2-registration-guide',
      ],
    },
    {
      type: 'category',
      label: 'L2 Integration',
      items: [
        '12-optimism-integration',
      ],
    },
    {
      type: 'category',
      label: 'Testing & Operations',
      items: [
        '10-v3-test-lists',
        '11-seigniorage-update-cases',
      ],
    },
  ],
};

export default sidebars;
