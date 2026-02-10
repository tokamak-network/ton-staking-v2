import { useAbiEvents } from "../hooks/useAbiEvents";

interface AbiEventsPanelProps {
  abiNames: string[];
}

export const AbiEventsPanel = ({ abiNames }: AbiEventsPanelProps) => {
  const { eventsMap, loading } = useAbiEvents(abiNames);

  return (
    <div>
      <h3>ABI Event List</h3>
      {loading && <p style={{ color: "#8ea0bf" }}>Loading ABI events...</p>}
      {abiNames.length === 0 ? (
        <p style={{ color: "#8ea0bf" }}>No ABI names available.</p>
      ) : (
        abiNames.map((name) => (
          <div key={name} style={{ marginBottom: "12px" }}>
            <div style={{ fontWeight: 600, marginBottom: 6 }}>{name}</div>
            <div
              style={{
                background: "#0d1320",
                borderRadius: "8px",
                padding: "8px",
                fontFamily: "monospace",
                fontSize: "12px"
              }}
            >
              {eventsMap[name]?.length ? eventsMap[name].join(", ") : "No events"}
            </div>
          </div>
        ))
      )}
    </div>
  );
};
