import { useEffect, useMemo, useState } from "react";
import { api } from "../lib/api";
import { ChallengersConfig, Deployments, NetworksConfig, Scenario, ScenarioConfig } from "../lib/types";
import { ScenarioSelector } from "../components/ScenarioSelector";
import { Stepper } from "../components/Stepper";
import { LogPanel } from "../components/LogPanel";
import { ConfigPanel } from "../components/ConfigPanel";
import { RunControls } from "../components/RunControls";
import { extractMarkers } from "../lib/formatters";
import { useDemoStatus } from "../hooks/useDemoStatus";

export default function Home() {
  const [scenarios, setScenarios] = useState<Scenario[]>([]);
  const [selectedScenario, setSelectedScenario] = useState<string>("");
  const [deployments, setDeployments] = useState<Deployments>();
  const [challengers, setChallengers] = useState<ChallengersConfig>();
  const [networks, setNetworks] = useState<NetworksConfig>();
  const [runId, setRunId] = useState<string | undefined>();

  const { status: run, logs, error } = useDemoStatus(runId);
  const markers = useMemo(() => extractMarkers(logs), [logs]);

  useEffect(() => {
    const loadConfig = async () => {
      const scenarioData: ScenarioConfig = await api.getScenarios();
      setScenarios(scenarioData.scenarios ?? []);
      if (scenarioData.scenarios?.length) {
        setSelectedScenario(scenarioData.scenarios[0].key);
      }
      setDeployments(await api.getDeployments());
      setChallengers(await api.getChallengers());
      setNetworks(await api.getNetworks());
    };

    void loadConfig();
  }, []);

  const startDemo = async () => {
    if (!selectedScenario) return;
    const runData = await api.startDemo(selectedScenario);
    setRunId(runData.id);
  };

  const stopDemo = async () => {
    if (!runId) return;
    await api.stopDemo(runId);
  };

  return (
    <main>
      <h1>TON Slashing Demo (Multi-Challenger)</h1>
      <p style={{ color: "#8ea0bf" }}>
        DisputeGame에서 챌린저 승리 → Slashing → Reward 분배 과정을 UI에서 시각화합니다.
      </p>

      <section>
        <ScenarioSelector
          scenarios={scenarios}
          selected={selectedScenario}
          onChange={setSelectedScenario}
        />
      </section>

      <section>
        <RunControls
          run={run}
          onStart={startDemo}
          onStop={stopDemo}
          isRunning={run?.status === "running"}
        />
        {error && <p style={{ color: "#ff9a9a" }}>Error: {error}</p>}
      </section>

      <section>
        <Stepper markers={markers} />
      </section>

      <section>
        <LogPanel logs={logs} />
      </section>

      <section>
        <ConfigPanel deployments={deployments} challengers={challengers} networks={networks} />
      </section>
    </main>
  );
}
