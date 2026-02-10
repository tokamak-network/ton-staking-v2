import { ChallengersConfig, Deployments, DemoRun, EventsConfig, NetworksConfig, ScenarioConfig } from "./types";

const baseUrl =
  process.env.NEXT_PUBLIC_DEMO_API_URL ?? "http://localhost:4000";

const fetchJson = async <T>(path: string, options?: RequestInit): Promise<T> => {
  const response = await fetch(`${baseUrl}${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...(options?.headers ?? {})
    }
  });
  if (!response.ok) {
    throw new Error(`Request failed: ${response.status}`);
  }
  return response.json() as Promise<T>;
};

export const api = {
  getScenarios: () => fetchJson<ScenarioConfig>("/config/scenarios"),
  getDeployments: () => fetchJson<Deployments>("/config/deployments"),
  getChallengers: () => fetchJson<ChallengersConfig>("/config/challengers"),
  getNetworks: () => fetchJson<NetworksConfig>("/config/networks"),
  getEvents: () => fetchJson<EventsConfig>("/config/events"),
  getAbi: (name: string) => fetchJson<any>(`/config/abi/${name}`),
  getAbiEvents: (name: string) =>
    fetchJson<{ events: string[] }>(`/config/abi/${name}/events`),
  startDemo: (scenarioKey: string) =>
    fetchJson<DemoRun>("/demo/start", {
      method: "POST",
      body: JSON.stringify({ scenarioKey })
    }),
  stopDemo: (runId: string) =>
    fetchJson<{ stopped: boolean }>(`/demo/stop/${runId}`, { method: "POST" }),
  getStatus: (runId: string) => fetchJson<DemoRun>(`/demo/status/${runId}`),
  getLogs: (runId: string) => fetchJson<{ logs: string[] }>(`/demo/logs/${runId}`)
};
