import { EventsConfig } from "../lib/types";
import { useAbiEvents } from "../hooks/useAbiEvents";
import { findBestMatch } from "../lib/string";

const THRESHOLD = 0.6;

interface EventConfigWarningsProps {
  eventsConfig?: EventsConfig;
}

export const EventConfigWarnings = ({ eventsConfig }: EventConfigWarningsProps) => {
  const abiNames = Array.from(new Set(eventsConfig?.steps?.map((s) => s.abi) ?? []));
  const { eventsMap, loading } = useAbiEvents(abiNames);

  const issues: string[] = [];

  if (eventsConfig?.steps) {
    for (const step of eventsConfig.steps) {
      const events = eventsMap[step.abi];
      if (!events || events.length === 0) {
        issues.push(`[${step.key}] ABI not found or empty: ${step.abi}`);
        continue;
      }
      if (!events.includes(step.event)) {
        const { best, score } = findBestMatch(step.event, events);
        if (best && score >= THRESHOLD) {
          issues.push(
            `[${step.key}] Event not found: ${step.abi}.${step.event} → 추천: ${best} (score ${score.toFixed(2)})`
          );
        } else {
          issues.push(`[${step.key}] Event not found in ABI: ${step.abi}.${step.event}`);
        }
      }
    }
  }

  return (
    <div>
      <h3>Event Config Warnings</h3>
      {loading && <p style={{ color: "#8ea0bf" }}>Validating event config...</p>}
      {issues.length === 0 ? (
        <p style={{ color: "#7ce6a8" }}>No issues detected.</p>
      ) : (
        <ul style={{ color: "#ff9a9a" }}>
          {issues.map((issue) => (
            <li key={issue}>{issue}</li>
          ))}
        </ul>
      )}
    </div>
  );
};
