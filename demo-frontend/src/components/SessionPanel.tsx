import { api } from "../lib/api";
import { useDemoSession } from "../hooks/useDemoSession";

export const SessionPanel = () => {
  const { state } = useDemoSession();

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
    </div>
  );
};
