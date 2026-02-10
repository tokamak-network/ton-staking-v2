import { useMemo, useState } from "react";

interface LogPanelProps {
  logs: string[];
}

export const LogPanel = ({ logs }: LogPanelProps) => {
  const [query, setQuery] = useState("");

  const filtered = useMemo(() => {
    if (!query) return logs;
    return logs.filter((line) => line.toLowerCase().includes(query.toLowerCase()));
  }, [logs, query]);

  return (
    <div>
      <h3>Logs</h3>
      <input
        placeholder="Filter logs..."
        value={query}
        onChange={(event) => setQuery(event.target.value)}
        style={{
          width: "100%",
          padding: "8px 12px",
          marginBottom: "12px",
          borderRadius: "8px"
        }}
      />
      <div
        style={{
          background: "#0d1320",
          borderRadius: "8px",
          padding: "12px",
          height: "300px",
          overflowY: "auto",
          fontFamily: "monospace",
          fontSize: "12px"
        }}
      >
        {filtered.length === 0 ? (
          <p style={{ color: "#8ea0bf" }}>No logs yet.</p>
        ) : (
          filtered.map((line, idx) => (
            <div key={`${line}-${idx}`} style={{ marginBottom: "6px" }}>
              {line}
            </div>
          ))
        )}
      </div>
    </div>
  );
};
