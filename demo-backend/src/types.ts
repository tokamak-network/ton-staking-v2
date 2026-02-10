export type DemoStatus = "idle" | "running" | "success" | "failed" | "stopped";

export interface DemoScenario {
  key: string;
  label: string;
  description?: string;
  script: string;
  testName?: string;
}

export interface DemoRun {
  id: string;
  scenarioKey: string;
  status: DemoStatus;
  startedAt: string;
  finishedAt?: string;
  exitCode?: number | null;
  pid?: number;
  logs: string[];
}
