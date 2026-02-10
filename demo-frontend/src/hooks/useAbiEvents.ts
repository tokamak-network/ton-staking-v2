import { useEffect, useState } from "react";
import { api } from "../lib/api";

export const useAbiEvents = (abiNames: string[]) => {
  const [eventsMap, setEventsMap] = useState<Record<string, string[]>>({});
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const load = async () => {
      setLoading(true);
      const map: Record<string, string[]> = {};
      for (const name of abiNames) {
        try {
          const data = await api.getAbiEvents(name);
          map[name] = data.events ?? [];
        } catch {
          map[name] = [];
        }
      }
      setEventsMap(map);
      setLoading(false);
    };

    if (abiNames.length > 0) {
      void load();
    } else {
      setEventsMap({});
    }
  }, [abiNames]);

  return { eventsMap, loading };
};
