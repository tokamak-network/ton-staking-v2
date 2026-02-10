import { JsonRpcProvider, Interface, Log } from "ethers";
import { Deployments, EventStepConfig, NetworksConfig } from "./types";

const baseApiUrl =
  process.env.NEXT_PUBLIC_DEMO_API_URL ?? "http://localhost:4000";

export const getProvider = (networks: NetworksConfig | undefined, network: "l1" | "l2") => {
  const proxyUrl = `${baseApiUrl}/rpc/${network}`;
  return new JsonRpcProvider(proxyUrl);
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

export const getEventTopicFromAbi = (abi: any[], eventName: string) => {
  const iface = new Interface(abi);
  const event = iface.getEvent(eventName);
  return iface.getEventTopic(event);
};

export const decodeEventWithAbi = (abi: any[], eventName: string, log: Log) => {
  const iface = new Interface(abi);
  const event = iface.getEvent(eventName);
  return iface.decodeEventLog(event, log.data, log.topics);
};

export const getEventNamesFromAbi = (abi: any[]) =>
  abi.filter((item) => item.type === "event").map((item) => item.name);

export const isGameCreatedEvent = (step: EventStepConfig) =>
  step.key === "GAME_CREATED";
