interface EventPanelProps {
  events: Array<{
    stepKey: string;
    txHash: string;
    blockNumber: number;
    network: string;
    address: string;
  }>;
  latestGame?: string;
}

export const EventPanel = ({ events, latestGame }: EventPanelProps) => {
  return (
    <div>
      <h3>On-Chain Events</h3>
      {latestGame && (
        <p style={{ color: "#8ea0bf" }}>Latest Game: {latestGame}</p>
      )}
      <div
        style={{
          background: "#0d1320",
          borderRadius: "8px",
          padding: "12px",
          maxHeight: "280px",
          overflowY: "auto",
          fontFamily: "monospace",
          fontSize: "12px"
        }}
      >
        {events.length === 0 ? (
          <p style={{ color: "#8ea0bf" }}>No events captured.</p>
        ) : (
          events.map((evt, idx) => (
            <div key={`${evt.txHash}-${idx}`} style={{ marginBottom: "8px" }}>
              [{evt.network}] {evt.stepKey} @ {evt.blockNumber} <br />
              {evt.address} <br />
              tx: {evt.txHash}
            </div>
          ))
        )}
      </div>
    </div>
  );
};
