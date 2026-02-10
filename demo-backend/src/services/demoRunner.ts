import { spawn } from "child_process";
import path from "path";
import { randomUUID } from "crypto";
import { DemoStore } from "./demoStore.js";
import { DemoRun, DemoScenario } from "../types.js";
import { readJsonFile } from "../utils/fs.js";
import { config } from "../config.js";

interface ScenarioConfig {
  scenarios: DemoScenario[];
}

export class DemoRunner {
  constructor(private store: DemoStore) {}

  listScenarios(): DemoScenario[] {
    const data = readJsonFile<ScenarioConfig>(config.scenariosPath);
    return data.scenarios ?? [];
  }

  startScenario(scenarioKey: string): DemoRun {
    const scenarios = this.listScenarios();
    const scenario = scenarios.find((item) => item.key === scenarioKey);
    if (!scenario) {
      throw new Error(`Scenario not found: ${scenarioKey}`);
    }

    const runId = randomUUID();
    const now = new Date().toISOString();
    const run: DemoRun = {
      id: runId,
      scenarioKey,
      status: "running",
      startedAt: now,
      logs: []
    };

    this.store.createRun(run);

    const scriptPath = path.resolve(config.scriptBase, scenario.script);
    const env = {
      ...process.env,
      TEST_NAME: scenario.testName ?? process.env.TEST_NAME ?? "",
      DEMO_SCENARIO_KEY: scenario.key
    };

    const child = spawn("bash", [scriptPath], {
      cwd: config.rootDir,
      env
    });

    this.store.attachPid(runId, child.pid);

    child.stdout.on("data", (data) => {
      data
        .toString()
        .split("\n")
        .filter(Boolean)
        .forEach((line) => this.store.appendLog(runId, line));
    });

    child.stderr.on("data", (data) => {
      data
        .toString()
        .split("\n")
        .filter(Boolean)
        .forEach((line) => this.store.appendLog(runId, `[ERR] ${line}`));
    });

    child.on("close", (code) => {
      if (code === 0) {
        this.store.finalize(runId, "success", code);
      } else {
        this.store.finalize(runId, "failed", code);
      }
    });

    child.on("error", (err) => {
      this.store.appendLog(runId, `[ERR] ${err.message}`);
      this.store.finalize(runId, "failed", 1);
    });

    return run;
  }

  stopScenario(runId: string) {
    const run = this.store.getRun(runId);
    if (!run || !run.pid) return false;

    try {
      process.kill(run.pid, "SIGTERM");
      this.store.finalize(runId, "stopped", null);
      return true;
    } catch {
      return false;
    }
  }
}
