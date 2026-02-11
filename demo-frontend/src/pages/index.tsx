import { useEffect, useMemo, useState } from "react";
import { api } from "../lib/api";
import {
  ChallengersConfig,
  Deployments,
  EventsConfig,
  NetworksConfig
} from "../lib/types";
import { ConfigPanel } from "../components/ConfigPanel";
import { useEventStepper } from "../hooks/useEventStepper";
import { RpcStatusPanel } from "../components/RpcStatusPanel";
import { AbiEventsPanel } from "../components/AbiEventsPanel";
import { EventConfigWarnings } from "../components/EventConfigWarnings";
import { SessionPanel } from "../components/SessionPanel";

export default function Home() {
  const [deployments, setDeployments] = useState<Deployments>();
  const [challengers, setChallengers] = useState<ChallengersConfig>();
  const [networks, setNetworks] = useState<NetworksConfig>();
  const [eventsConfig, setEventsConfig] = useState<EventsConfig>();

  const { games, selectedGame, setSelectedGame } = useEventStepper({
    eventsConfig,
    networks,
    deployments,
    runId: "session"
  });

  const abiNames = useMemo(() => {
    return Array.from(new Set(eventsConfig?.steps?.map((s) => s.abi) ?? []));
  }, [eventsConfig]);

  useEffect(() => {
    const loadConfig = async () => {
      setDeployments(await api.getDeployments());
      setChallengers(await api.getChallengers());
      setNetworks(await api.getNetworks());
      setEventsConfig(await api.getEvents());
    };

    void loadConfig();
  }, []);

  return (
    <main>
      <h1>TON Slashing Demo (Multi-Challenger)</h1>
      <p style={{ color: "#8ea0bf" }}>
        DisputeGame에서 챌린저 승리 → Slashing → Reward 분배 과정을 UI에서 시각화합니다.
      </p>

      <section>
        <SessionPanel />
      </section>

      <section className="section-panel">
        <RpcStatusPanel networks={networks} />
      </section>

      <section className="section-panel">
        <EventConfigWarnings eventsConfig={eventsConfig} />
      </section>

      <section className="section-panel">
        <AbiEventsPanel abiNames={abiNames} />
      </section>

      <section className="section-panel">
        <ConfigPanel deployments={deployments} challengers={challengers} networks={networks} />
      </section>
    </main>
  );
}
