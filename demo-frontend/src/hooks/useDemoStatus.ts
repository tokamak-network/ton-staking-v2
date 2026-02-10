import { useEffect, useState } from "react";
import { api } from "../lib/api";
import { DemoRun } from "../lib/types";
import { useInterval } from "./useInterval";

export const useDemoStatus = (runId?: string) => {
  const [status, setStatus] = useState<DemoRun | null>(null);
  const [logs, setLogs] = useState<string[]>([]);
  const [error, setError] = useState<string | null>(null);

  const fetchStatus = async () => {
    if (!runId) return;
    try {
      const run = await api.getStatus(runId);
      setStatus(run);
    } catch (err) {
      setError((err as Error).message);
    }
  };

  const fetchLogs = async () => {
    if (!runId) return;
    try {
      const data = await api.getLogs(runId);
      setLogs(data.logs ?? []);
    } catch (err) {
      setError((err as Error).message);
    }
  };

  useEffect(() => {
    setStatus(null);
    setLogs([]);
    setError(null);
  }, [runId]);

  useInterval(() => {
    void fetchStatus();
    void fetchLogs();
  }, runId ? 2000 : null);

  return { status, logs, error, refresh: () => void (fetchStatus(), fetchLogs()) };
};
