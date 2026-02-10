import { useEffect, useState } from "react";
import { api } from "../lib/api";

export const useDemoSession = () => {
  const [state, setState] = useState<any>(null);

  const load = async () => {
    try {
      const data = await api.getSessionState();
      setState(data);
    } catch {
      setState(null);
    }
  };

  useEffect(() => {
    void load();
    const interval = setInterval(load, 5000);
    return () => clearInterval(interval);
  }, []);

  return { state, refresh: load };
};
