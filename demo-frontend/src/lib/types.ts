export interface ScenarioConfig {
  scenarios: Scenario[];
}

export interface Scenario {
  key: string;
  label: string;
  description?: string;
  script: string;
  testName?: string;
}

export interface DemoRun {
  id: string;
  scenarioKey: string;
  status: "idle" | "running" | "success" | "failed" | "stopped";
  startedAt: string;
  finishedAt?: string;
  exitCode?: number | null;
  pid?: number;
  logs: string[];
}

export interface ChallengersConfig {
  rewardToken: {
    symbol: string;
    address: string;
  };
  challengers: { label: string; address: string }[];
  notes?: string;
}

export type Deployments = Record<string, string>;

export type NetworksConfig = Record<string, unknown>;

export interface EventStepConfig {
  key: string;
  network: "l1" | "l2";
  addressRef: string;
  signature: string;
}

export interface EventsConfig {
  steps: EventStepConfig[];
  notes?: string;
}
