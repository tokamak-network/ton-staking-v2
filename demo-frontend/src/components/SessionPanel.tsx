import { useEffect, useMemo, useState } from "react";
import { api } from "../lib/api";
import { useDemoSession } from "../hooks/useDemoSession";
import { formatToken } from "../lib/formatToken";

export const SessionPanel = () => {
  const { state, refresh } = useDemoSession();
  const [mode, setMode] = useState<"single" | "multi">("single");
  const [logs, setLogs] = useState("");
  const [copied, setCopied] = useState(false);

  const loadLogs = async () => {
    try {
      const data = await api.getSessionLogs();
      setLogs(data.logs ?? "");
    } catch {
      setLogs("");
    }
  };

  useEffect(() => {
    void loadLogs();
    const interval = setInterval(loadLogs, 5000);
    return () => clearInterval(interval);
  }, []);

  const formatWton = (value?: string) => {
    const formatted = formatToken(value, 27, 0);
    return formatted === "-" ? "-" : `${formatted} WTON`;
  };

  const formattedStakeBefore = formatWton(state?.stakeBefore);
  const formattedStakeAfter = formatWton(state?.stakeAfter);
  const formattedRewardDelta = formatWton(state?.rewardDelta);
  const formattedBalanceBefore = formatWton(state?.challengerBalanceBefore);
  const formattedBalanceAfter = formatWton(state?.challengerBalanceAfter);

  const formatBasisPoints = (value?: string) => {
    if (!value) return "-";
    try {
      const bp = BigInt(value);
      const integer = bp / 100n;
      const fraction = (bp % 100n).toString().padStart(2, "0");
      return `${integer.toString()}.${fraction}%`;
    } catch {
      return "-";
    }
  };

  const formattedSlashingRewardRate = formatBasisPoints(state?.slashingRewardRate);

  const statusClass = useMemo(() => {
    if (state?.status === "slashed") return "badge badge-success";
    if (state?.status === "ready") return "badge badge-info";
    if (state?.status === "error") return "badge badge-danger";
    return "badge badge-muted";
  }, [state?.status]);

  const handleReset = async () => {
    try {
      await api.resetSession();
    } catch {
      // ignore errors to keep UX simple
    } finally {
      await refresh();
    }
  };

  const logLines = logs.split("\n").slice(-200).join("\n");

  const handleCopyLogs = async () => {
    if (!logLines) return;
    try {
      await navigator.clipboard.writeText(logLines);
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    } catch {
      alert("Failed to copy logs.");
    }
  };

  return (
    <div className="panel">
      <div className="panel-header">
        <div>
          <h3 className="panel-title">Interactive Demo Session</h3>
          <p className="panel-subtitle">Slash flow status, rewards, and live session info.</p>
        </div>
        {state?.status && <span className={statusClass}>{state.status}</span>}
      </div>

      <div className="action-bar">
        <div className="select-wrap">
          <span className="select-icon">🎛️</span>
          <select
            value={mode}
            onChange={(e) => setMode(e.target.value as "single" | "multi")}
          >
            <option value="single">Single Challenger</option>
            <option value="multi">Two Challengers</option>
          </select>
        </div>

        <button className="btn btn-primary" onClick={() => api.startSession(mode)}>
          ▶️ Start Demo Session
        </button>
        <button className="btn btn-danger" onClick={() => api.slashSession()}>
          ⚔️ Slash Operator
        </button>
        <button className="btn btn-warning" onClick={() => api.stopSession()}>
          ⏹ Stop Session
        </button>
        <button className="btn btn-muted" onClick={handleReset}>
          ♻️ Reset Session
        </button>
      </div>

      {!state ? (
        <div className="empty-state">No session state yet.</div>
      ) : (
        <div className="card">
          <div className="card-header">
            <h4>Session Overview</h4>
            <span className="muted">{state.message}</span>
          </div>
          <div className="kv-grid">
            <div className="kv-item">
              <div className="kv-label">Mode</div>
              <div className="kv-value">{state.mode}</div>
            </div>
            <div className="kv-item">
              <div className="kv-label">OperatorManager</div>
              <div className="kv-value mono">{state.operatorManager}</div>
            </div>
            <div className="kv-item">
              <div className="kv-label">Game Address</div>
              <div className="kv-value mono">{state.gameAddress}</div>
            </div>
            <div className="kv-item">
              <div className="kv-label">Challenger</div>
              <div className="kv-value mono">{state.challenger}</div>
            </div>
            <div className="kv-item">
              <div className="kv-label">Winning Challengers</div>
              <div className="kv-value mono">
                {(state.winningChallengers || []).join(", ")}
              </div>
            </div>
            <div className="kv-item">
              <div className="kv-label">Slashing Tx</div>
              <div className="kv-value mono">{state.slashingTxHash || "-"}</div>
            </div>
            <div className="kv-item">
              <div className="kv-label">Stake Before</div>
              <div className="kv-value">{formattedStakeBefore}</div>
            </div>
            <div className="kv-item">
              <div className="kv-label">Stake After</div>
              <div className="kv-value">{formattedStakeAfter}</div>
            </div>
            <div className="kv-item">
              <div className="kv-label">Reward Delta</div>
              <div className="kv-value">{formattedRewardDelta}</div>
            </div>
            <div className="kv-item">
              <div className="kv-label">Slashing Reward Rate</div>
              <div className="kv-value">{formattedSlashingRewardRate}</div>
            </div>
            <div className="kv-item">
              <div className="kv-label">Challenger Balance (Before)</div>
              <div className="kv-value">{formattedBalanceBefore}</div>
            </div>
            <div className="kv-item">
              <div className="kv-label">Challenger Balance (After)</div>
              <div className="kv-value">{formattedBalanceAfter}</div>
            </div>
          </div>
        </div>
      )}

      <div className="card">
        <div className="card-header">
          <h4>Timeline</h4>
          <span className="muted">Recent flow checkpoints</span>
        </div>
        <ol className="timeline">
          {(state?.timeline || []).map((item: any, idx: number) => (
            <li key={`${item.step}-${idx}`}>
              <span className="timeline-time">{item.time}</span>
              <span className="timeline-step">{item.step}</span>
              <span className="timeline-message">{item.message}</span>
            </li>
          ))}
        </ol>
      </div>

      <div className="card">
        <div className="card-header logs-header">
          <div>
            <h4>Session Logs</h4>
            <span className="muted">Last 200 lines</span>
          </div>
          <button
            onClick={handleCopyLogs}
            disabled={!logLines}
            className={`btn btn-ghost ${copied ? "btn-success" : ""}`}
          >
            {copied ? "✅ Copied!" : "📋 Copy logs"}
          </button>
        </div>
        <div className="logs-box">{logLines || "No logs yet."}</div>
      </div>
    </div>
  );
};
