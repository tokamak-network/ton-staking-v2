import { useEffect, useState } from "react";
import { api } from "../lib/api";
import { useDemoSession } from "../hooks/useDemoSession";

export const SessionPanel = () => {
  const { state } = useDemoSession();
  const [logs, setLogs] = useState("");

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
    const interval = setInterval(load, 3000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div>
      <h3>Interactive Demo Session</h3>
      <div style={{ display: "flex", gap: 10, marginBottom: 12 }}>
        <button onClick={() => api.startSession()}>Start Demo Session</button>
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
          <div>OperatorManager: {state.operatorManager}</div>
          <div>GameAddress: {state.gameAddress}</div>
          <div>Challenger: {state.challenger}</div>
          <div>Stake Before: {state.stakeBefore}</div>
          <div>Stake After: {state.stakeAfter ?? "-"}</div>
          <div>Challenger Balance Before: {state.challengerBalanceBefore}</div>
          <div>Challenger Balance After: {state.challengerBalanceAfter ?? "-"}</div>
        </div>
      )}

      <h4 style={{ marginTop: 16 }}>Session Logs</h4>
      <div
        style={{
          background: "#0d1320",
          borderRadius: "8px",
          padding: "12px",
          height: "180px",
          overflowY: "auto",
          fontFamily: "monospace",
          fontSize: "12px",
          color: "#8ea0bf"
        }}
      >
        {logs || "No logs yet."}
      </div>
    </div>
  );
};
