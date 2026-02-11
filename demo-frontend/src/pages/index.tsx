import { useEffect, useMemo, useState } from "react";
import { api } from "../lib/api";
import {
  ChallengersConfig,
  Deployments,
  EventsConfig,
  NetworksConfig
} from "../lib/types";
import { Stepper } from "../components/Stepper";
import { LogPanel } from "../components/LogPanel";
import { ConfigPanel } from "../components/ConfigPanel";
import { extractMarkers } from "../lib/formatters";
import { useEventStepper } from "../hooks/useEventStepper";
import { RpcStatusPanel } from "../components/RpcStatusPanel";
import { ChallengerBalancesPanel } from "../components/ChallengerBalancesPanel";
import { EventPanel } from "../components/EventPanel";
import { AbiEventsPanel } from "../components/AbiEventsPanel";
import { EventConfigWarnings } from "../components/EventConfigWarnings";
import { GameSelector } from "../components/GameSelector";
import { SessionPanel } from "../components/SessionPanel";

export default function Home() {
  const [deployments, setDeployments] = useState<Deployments>();
  const [challengers, setChallengers] = useState<ChallengersConfig>();
  const [networks, setNetworks] = useState<NetworksConfig>();
  const [eventsConfig, setEventsConfig] = useState<EventsConfig>();

  const {
    markers: eventMarkers,
    captured,
    games,
    selectedGame,
    setSelectedGame
  } = useEventStepper({
    eventsConfig,
    networks,
    deployments,
    runId: "session"
  });

  const stepperMarkers = eventMarkers.length ? eventMarkers : [];

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

      <section>
        <Stepper markers={stepperMarkers} />
      </section>

      <section>
        <GameSelector
          games={games}
          selectedGame={selectedGame}
          onSelect={setSelectedGame}
        />
      </section>

      <section>
        <EventPanel events={captured} />
      </section>

      <section>
        <RpcStatusPanel networks={networks} />
      </section>

      <section>
        <ChallengerBalancesPanel challengers={challengers} networks={networks} />
      </section>

      <section>
        <EventConfigWarnings eventsConfig={eventsConfig} />
      </section>

      <section>
        <AbiEventsPanel abiNames={abiNames} />
      </section>

      <section>
        <LogPanel logs={extractMarkers([])} />
      </section>

      <section>
        <ConfigPanel deployments={deployments} challengers={challengers} networks={networks} />
      </section>
    </main>
  );
}
