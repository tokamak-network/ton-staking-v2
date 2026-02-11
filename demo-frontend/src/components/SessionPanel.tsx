import { useEffect, useState } from "react";
import { api } from "../lib/api";
import { useDemoSession } from "../hooks/useDemoSession";
import { formatToken } from "../lib/formatToken";

export const SessionPanel = () => {
  const { state } = useDemoSession();
  const [logs, setLogs] = useState("");
  const [mode, setMode] = useState<"single" | "multi">("single");
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    const load = async () => {
      try {
        const data = await api.getSessionLogs();
        setLogs(data.logs ?? "");
      } catch {
        setLogs("");
      }
    };
    void load();
    const interval = setInterval(load, 5000);
    return () => clearInterval(interval);
  }, []);

  const formattedStakeBefore = formatToken(state?.stakeBefore);
  const formattedStakeAfter = formatToken(state?.stakeAfter);
  const formattedRewardDelta = formatToken(state?.rewardDelta);
  const formattedBalanceBefore = formatToken(state?.challengerBalanceBefore);
  const formattedBalanceAfter = formatToken(state?.challengerBalanceAfter);

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
    <div>
      <h3>Interactive Demo Session</h3>

      <div style={{ display: "flex", gap: 10, marginBottom: 12 }}>
        <select
          value={mode}
          onChange={(e) => setMode(e.target.value as "single" | "multi")}
          style={{ padding: "6px 10px", borderRadius: "6px" }}
        >
          <option value="single">Single Challenger</option>
          <option value="multi">Two Challengers</option>
        </select>

        <button onClick={() => api.startSession(mode)}>Start Demo Session</button>
        <button onClick={() => api.slashSession()} style={{ background: "#ef4444" }}>
          Slash Operator
        </button>
        <button onClick={() => api.stopSession()} style={{ background: "#f59e0b" }}>
          Stop Session
        </button>
      </div>

      {!state ? (
        <p style={{ color: "#8ea0bf" }}>No session state yet.</p>
      ) : (
        <div style={{ color: "#8ea0bf", fontSize: 14 }}>
          <div>Status: {state.status}</div>
          <div>Message: {state.message}</div>
          <div>Mode: {state.mode}</div>
          <div>OperatorManager: {state.operatorManager}</div>
          <div>GameAddress: {state.gameAddress}</div>
          <div>Challenger: {state.challenger}</div>
          <div>Winning Challengers: {(state.winningChallengers || []).join(", ")}</div>
          <div>Slashing Tx: {state.slashingTxHash || "-"}</div>

          <div>Stake Before: {formattedStakeBefore} (raw: {state.stakeBefore})</div>
          <div>Stake After: {formattedStakeAfter} (raw: {state.stakeAfter || "-"})</div>
          <div>Reward Delta: {formattedRewardDelta} (raw: {state.rewardDelta || "-"})</div>

          <div>Challenger Balance Before: {formattedBalanceBefore}</div>
          <div>Challenger Balance After: {formattedBalanceAfter}</div>
        </div>
      )}

      <h4 style={{ marginTop: 16 }}>Timeline</h4>
      <ol style={{ color: "#8ea0bf", fontSize: 13 }}>
        {(state?.timeline || []).map((item: any, idx: number) => (
          <li key={`${item.step}-${idx}`}>
            {item.time} - {item.step} - {item.message}
          </li>
        ))}
      </ol>

      <div style={{ display: "flex", alignItems: "center", gap: 12, marginTop: 16 }}>
        <h4 style={{ margin: 0 }}>Session Logs (last 200 lines)</h4>
        <button
          onClick={handleCopyLogs}
          disabled={!logLines}
          style={{
            padding: "6px 10px",
            borderRadius: "6px",
            background: copied ? "#22c55e" : "#1f2937",
            color: "#fff"
          }}
        >
          {copied ? "Copied!" : "Copy logs"}
        </button>
      </div>
      <div
        style={{
          background: "#0d1320",
          borderRadius: "8px",
          padding: "16px",
          height: "420px",
          overflowY: "auto",
          fontFamily: "monospace",
          fontSize: "13px",
          lineHeight: "1.5",
          color: "#8ea0bf",
          whiteSpace: "pre-wrap"
        }}
      >
        {logLines || "No logs yet."}
      </div>
    </div>
  );
};
