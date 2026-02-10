import { useEffect, useMemo, useRef, useState } from "react";
import { Deployments, EventsConfig, NetworksConfig } from "../lib/types";
import { decodeEvent, getEventTopic, getProvider, isGameCreatedEvent, resolveAddress } from "../lib/chain";

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

export const useEventStepper = ({
  eventsConfig,
  networks,
  deployments,
  runId
}: UseEventStepperParams) => {
  const [markers, setMarkers] = useState<string[]>([]);
  const [captured, setCaptured] = useState<CapturedEvent[]>([]);
  const [latestGame, setLatestGame] = useState<string | undefined>();
  const lastBlocksRef = useRef<{ l1?: number; l2?: number }>({});

  const steps = eventsConfig?.steps ?? [];
  const l1Provider = useMemo(() => getProvider(networks, "l1"), [networks]);
  const l2Provider = useMemo(() => getProvider(networks, "l2"), [networks]);

  useEffect(() => {
    setMarkers([]);
    setCaptured([]);
    setLatestGame(undefined);
    lastBlocksRef.current = {};
  }, [runId]);

  useEffect(() => {
    const initBlocks = async () => {
      if (l1Provider) {
        lastBlocksRef.current.l1 = await l1Provider.getBlockNumber();
      }
      if (l2Provider) {
        lastBlocksRef.current.l2 = await l2Provider.getBlockNumber();
      }
    };
    void initBlocks();
  }, [l1Provider, l2Provider, runId]);

  useEffect(() => {
    if (!steps.length || !l1Provider || !l2Provider) return;

    let active = true;

    const poll = async () => {
      const providers = { l1: l1Provider, l2: l2Provider };

      for (const step of steps) {
        const provider = providers[step.network];
        const address = resolveAddress(step.addressRef, deployments, latestGame);
        if (!provider || !address) continue;

        const fromBlock =
          step.network === "l1"
            ? lastBlocksRef.current.l1 ?? (await provider.getBlockNumber())
            : lastBlocksRef.current.l2 ?? (await provider.getBlockNumber());

        const toBlock = await provider.getBlockNumber();
        if (toBlock < fromBlock) continue;

        const topic = getEventTopic(step.signature);
        const logs = await provider.getLogs({
          address,
          fromBlock,
          toBlock,
          topics: [topic]
        });

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
              const decoded = decodeEvent(step.signature, logs[0]);
              const game = decoded?.[0] as string | undefined;
              if (game) setLatestGame(game);
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
  }, [steps, deployments, latestGame, l1Provider, l2Provider]);

  return { markers, captured, latestGame };
};
