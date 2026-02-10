import { Scenario } from "../lib/types";

interface ScenarioSelectorProps {
  scenarios: Scenario[];
  selected?: string;
  onChange: (value: string) => void;
}

export const ScenarioSelector = ({
  scenarios,
  selected,
  onChange
}: ScenarioSelectorProps) => {
  return (
    <div>
      <h3>Scenario</h3>
      <select
        value={selected}
        onChange={(event) => onChange(event.target.value)}
        style={{ width: "100%", padding: "10px", borderRadius: "8px" }}
      >
        {scenarios.map((scenario) => (
          <option key={scenario.key} value={scenario.key}>
            {scenario.label}
          </option>
        ))}
      </select>
      {selected && (
        <p style={{ color: "#8ea0bf", marginTop: "8px" }}>
          {scenarios.find((item) => item.key === selected)?.description}
        </p>
      )}
    </div>
  );
};
