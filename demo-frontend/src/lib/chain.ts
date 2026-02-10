import { JsonRpcProvider, Interface, Log } from "ethers";
import { Deployments, EventStepConfig, NetworksConfig } from "./types";

export const getProvider = (networks: NetworksConfig | undefined, network: "l1" | "l2") => {
  if (!networks) return null;
  const config = networks[network] as { rpcUrl?: string };
  if (!config?.rpcUrl) return null;
  return new JsonRpcProvider(config.rpcUrl);
};

export const resolveAddress = (
  ref: string,
  deployments: Deployments | undefined,
  latestGame?: string
) => {
  if (ref.startsWith("deployment:")) {
    const key = ref.replace("deployment:", "");
    return deployments?.[key];
  }
  if (ref === "game:latest") {
    return latestGame;
  }
  return ref;
};

export const getEventTopic = (signature: string) => {
  const eventName = signature.split("(")[0];
  const iface = new Interface([`event ${signature}`]);
  const event = iface.getEvent(eventName);
  return iface.getEventTopic(event);
};

export const decodeEvent = (signature: string, log: Log) => {
  const eventName = signature.split("(")[0];
  const iface = new Interface([`event ${signature}`]);
  const event = iface.getEvent(eventName);
  return iface.decodeEventLog(event, log.data, log.topics);
};

export const isGameCreatedEvent = (step: EventStepConfig) =>
  step.key === "GAME_CREATED";
