import { useEffect, useMemo, useRef, useState } from "react";
import { Deployments, EventsConfig, NetworksConfig } from "../lib/types";
import {
  decodeEventWithAbi,
  getEventNamesFromAbi,
  getEventTopicFromAbi,
  getProvider,
  isGameCreatedEvent,
  resolveAddress
} from "../lib/chain";
import { api } from "../lib/api";
import { findBestMatch } from "../lib/string";

interface CapturedEvent {
  stepKey: string;
  txHash: string;
  blockNumber: number;
  network: "l1" | "l2";
  address: string;
}

interface UseEventStepperParams {
  eventsConfig?: EventsConfig;
  networks?: NetworksConfig;
  deployments?: Deployments;
  runId?: string;
}

const AUTO_MATCH_THRESHOLD = 0.6;

export const useEventStepper = ({
  eventsConfig,
  networks,
  deployments,
  runId
}: UseEventStepperParams) => {
  const [markers, setMarkers] = useState<string[]>([]);
  const [captured, setCaptured] = useState<CapturedEvent[]>([]);
  const [games, setGames] = useState<string[]>([]);
  const [selectedGame, setSelectedGame] = useState<string | undefined>();
  const [abiMap, setAbiMap] = useState<Record<string, any[]>>({});
  const lastBlocksRef = useRef<{ l1?: number; l2?: number }>({});
  const startBlocksRef = useRef<{ l1?: number; l2?: number }>({});

  const steps = eventsConfig?.steps ?? [];
  const l1Provider = useMemo(() => getProvider(networks, "l1"), [networks]);
  const l2Provider = useMemo(() => getProvider(networks, "l2"), [networks]);

  useEffect(() => {
    setMarkers([]);
    setCaptured([]);
    setGames([]);
    setSelectedGame(undefined);
    lastBlocksRef.current = {};
    startBlocksRef.current = {};
  }, [runId]);

  useEffect(() => {
    const loadAbis = async () => {
      const names = Array.from(new Set(steps.map((s) => s.abi)));
      const results: Record<string, any[]> = {};
      for (const name of names) {
        try {
          results[name] = await api.getAbi(name);
        } catch {
          results[name] = [];
        }
      }
      setAbiMap(results);
    };

    if (steps.length > 0) {
      void loadAbis();
    }
  }, [steps]);

  useEffect(() => {
    const initBlocks = async () => {
      try {
        if (l1Provider) {
          startBlocksRef.current.l1 = await l1Provider.getBlockNumber();
        }
        if (l2Provider) {
          startBlocksRef.current.l2 = await l2Provider.getBlockNumber();
        }
      } catch {
        // ignore RPC errors at init
      }
    };
    void initBlocks();
  }, [l1Provider, l2Provider, runId]);

  useEffect(() => {
    if (selectedGame) {
      setMarkers([]);
      setCaptured([]);
      lastBlocksRef.current = { ...startBlocksRef.current };
    }
  }, [selectedGame]);

  useEffect(() => {
    if (!steps.length || !l1Provider || !l2Provider) return;

    let active = true;

    const poll = async () => {
      const providers = { l1: l1Provider, l2: l2Provider };

      for (const step of steps) {
        const provider = providers[step.network];
        const resolvedGame = selectedGame ?? games[games.length - 1];
        const address = resolveAddress(step.addressRef, deployments, resolvedGame);
        const abi = abiMap[step.abi];

        if (!provider || !address || !abi || abi.length === 0) continue;

        const eventNames = getEventNamesFromAbi(abi);
        const exactMatch = eventNames.includes(step.event) ? step.event : null;
        const { best, score } = findBestMatch(step.event, eventNames);
        const resolvedEvent =
          exactMatch ?? (score >= AUTO_MATCH_THRESHOLD ? best : null);

        if (!resolvedEvent) continue;

        let fromBlock: number | undefined;
        let toBlock: number;

        try {
          fromBlock =
            step.network === "l1"
              ? lastBlocksRef.current.l1 ?? startBlocksRef.current.l1
              : lastBlocksRef.current.l2 ?? startBlocksRef.current.l2;

          if (fromBlock === undefined) continue;

          toBlock = await provider.getBlockNumber();
        } catch {
          continue;
        }

        if (toBlock < fromBlock) continue;

        let topic: string;
        try {
          topic = getEventTopicFromAbi(abi, resolvedEvent);
        } catch {
          continue;
        }

        let logs = [];
        try {
          logs = await provider.getLogs({
            address,
            fromBlock,
            toBlock,
            topics: [topic]
          });
        } catch {
          continue;
        }

        if (!active) return;

        if (logs.length > 0) {
          setMarkers((prev) => {
            const set = new Set(prev);
            set.add(step.key);
            return Array.from(set);
          });

          logs.forEach((log) => {
            setCaptured((prev) => [
              ...prev,
              {
                stepKey: step.key,
                txHash: log.transactionHash,
                blockNumber: log.blockNumber,
                network: step.network,
                address
              }
            ]);
          });

          if (isGameCreatedEvent(step)) {
            try {
              const decoded = decodeEventWithAbi(abi, resolvedEvent, logs[0]);
              const game = decoded?.[0] as string | undefined;
              if (game) {
                setGames((prev) => (prev.includes(game) ? prev : [...prev, game]));
                if (!selectedGame) setSelectedGame(game);
              }
            } catch {
              // ignore decode errors
            }
          }
        }

        if (step.network === "l1") {
          lastBlocksRef.current.l1 = toBlock + 1;
        } else {
          lastBlocksRef.current.l2 = toBlock + 1;
        }
      }
    };

    const interval = setInterval(() => {
      void poll();
    }, 4000);

    return () => {
      active = false;
      clearInterval(interval);
    };
  }, [steps, deployments, selectedGame, games, l1Provider, l2Provider, abiMap]);

  return { markers, captured, games, selectedGame, setSelectedGame };
};
