import { DemoRun, DemoStatus } from "../types.js";

export class DemoStore {
  private runs = new Map<string, DemoRun>();

  createRun(run: DemoRun) {
    this.runs.set(run.id, run);
  }

  getRun(id: string) {
    return this.runs.get(id);
  }

  listRuns() {
    return Array.from(this.runs.values());
  }

  updateStatus(id: string, status: DemoStatus) {
    const run = this.runs.get(id);
    if (!run) return;
    run.status = status;
  }

  appendLog(id: string, line: string) {
    const run = this.runs.get(id);
    if (!run) return;
    run.logs.push(line);
  }

  finalize(id: string, status: DemoStatus, exitCode?: number | null) {
    const run = this.runs.get(id);
    if (!run) return;
    run.status = status;
    run.exitCode = exitCode ?? null;
    run.finishedAt = new Date().toISOString();
  }

  attachPid(id: string, pid?: number) {
    const run = this.runs.get(id);
    if (!run) return;
    run.pid = pid;
  }
}
