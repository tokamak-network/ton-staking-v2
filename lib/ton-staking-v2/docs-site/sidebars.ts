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
        {
          type: 'category',
          label: 'RAT Client',
          link: {
            type: 'generated-index',
            description: 'RAT Client implementation and operations specification for Type 3 rollups.',
          },
          items: [
            'rat-client/overview',
            'rat-client/adjacent-leaves-proof',
            'rat-client/solidity-implementation',
            'rat-client/go-client-implementation',
            'rat-client/outputrootproof-verification',
            'rat-client/deployment-operations',
          ],
        },
      ],
    },
    {
      type: 'category',
      label: 'Testing & Operations',
      items: [
        {
          type: 'category',
          label: 'V3 Tests',
          link: {
            type: 'generated-index',
            description: 'TON Staking V3 comprehensive test suite documentation.',
          },
          items: [
            'v3-tests/overview',
            'v3-tests/v2-mode-tests',
            'v3-tests/v3-mode-tests',
            'v3-tests/scenario-tests',
            'v3-tests/e2e-tests',
            'v3-tests/rat-client-unit-tests',
          ],
        },
        '11-seigniorage-update-cases',
      ],
    },
  ],
};

export default sidebars;
