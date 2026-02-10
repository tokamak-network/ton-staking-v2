import { DemoRun } from "../lib/types";
import { StatusBadge } from "./StatusBadge";
import { formatDateTime, formatDuration } from "../lib/formatters";

interface RunControlsProps {
  run?: DemoRun | null;
  onStart: () => void;
  onStop: () => void;
  isRunning: boolean;
}

export const RunControls = ({ run, onStart, onStop, isRunning }: RunControlsProps) => {
  return (
    <div>
      <h3>Run Controls</h3>
      <div style={{ display: "flex", gap: 12, alignItems: "center", marginBottom: 12 }}>
        <button onClick={onStart} disabled={isRunning}>
          Start Demo
        </button>
        <button onClick={onStop} disabled={!isRunning} style={{ background: "#f59e0b" }}>
          Stop Demo
        </button>
        <StatusBadge status={run?.status} />
      </div>
      <div style={{ color: "#8ea0bf", fontSize: "14px" }}>
        <div>Started: {formatDateTime(run?.startedAt)}</div>
        <div>Finished: {formatDateTime(run?.finishedAt)}</div>
        <div>Duration: {formatDuration(run?.startedAt, run?.finishedAt)}</div>
        <div>Exit Code: {run?.exitCode ?? "-"}</div>
      </div>
    </div>
  );
};
