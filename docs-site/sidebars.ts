import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  docsSidebar: [
    {
      type: 'doc',
      id: 'README',
      label: 'Introduction',
    },
    {
      type: 'category',
      label: 'Architecture',
      items: [
        '01_v2_architecture',
        '02_v3_distribution',
      ],
    },
    {
      type: 'category',
      label: 'Slashing',
      items: [
        '03_sequencer_slashing',
        '05_validator_slashing',
      ],
    },
    {
      type: 'category',
      label: 'Validator',
      items: [
        '04_validator',
        '06_bridged_ton_tracking',
      ],
    },
    {
      type: 'category',
      label: 'Implementation',
      items: [
        '07_rat_implementation',
        '08_implementation',
      ],
    },
    {
      type: 'category',
      label: 'Operations',
      items: [
        '09_migration',
        '10_governance_parameters',
      ],
    },
    {
      type: 'category',
      label: 'Additional (KO)',
      items: [
        '11_whitepaper_v2_changes',
        '12_tbd_items',
        '13_external_interfaces',
        '14_deployment',
        'optimism_integration_guide',
      ],
    },
  ],
};

export default sidebars;
