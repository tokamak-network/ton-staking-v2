import { ChallengersConfig, Deployments, NetworksConfig } from "../lib/types";
import { KeyValueTable } from "./KeyValueTable";

interface ConfigPanelProps {
  deployments?: Deployments;
  challengers?: ChallengersConfig;
  networks?: NetworksConfig;
}

export const ConfigPanel = ({ deployments, challengers, networks }: ConfigPanelProps) => {
  return (
    <div>
      <h3>Config Snapshot</h3>
      <section style={{ background: "#0f1522", marginBottom: "16px" }}>
        <h4>Networks</h4>
        <pre style={{ color: "#8ea0bf" }}>{JSON.stringify(networks ?? {}, null, 2)}</pre>
      </section>

      <section style={{ background: "#0f1522", marginBottom: "16px" }}>
        <h4>Challengers</h4>
        <pre style={{ color: "#8ea0bf" }}>{JSON.stringify(challengers ?? {}, null, 2)}</pre>
      </section>

      <section style={{ background: "#0f1522" }}>
        <h4>Deployments</h4>
        {deployments ? (
          <KeyValueTable
            entries={Object.entries(deployments).map(([key, value]) => ({
              key,
              value
            }))}
          />
        ) : (
          <p style={{ color: "#8ea0bf" }}>No deployment data.</p>
        )}
      </section>
    </div>
  );
};
