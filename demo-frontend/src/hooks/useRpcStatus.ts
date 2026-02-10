import { useEffect, useState } from "react";
import { JsonRpcProvider } from "ethers";
import { NetworksConfig } from "../lib/types";
import { getProvider } from "../lib/chain";

interface RpcStatus {
  network: "l1" | "l2";
  ok: boolean;
  blockNumber?: number;
  error?: string;
}

export const useRpcStatus = (networks?: NetworksConfig) => {
  const [status, setStatus] = useState<RpcStatus[]>([]);

  useEffect(() => {
    const load = async () => {
      const statuses: RpcStatus[] = [];

      const check = async (network: "l1" | "l2") => {
        const provider = getProvider(networks, network);
        if (!provider) {
          statuses.push({ network, ok: false, error: "RPC not configured" });
          return;
        }
        try {
          const blockNumber = await (provider as JsonRpcProvider).getBlockNumber();
          statuses.push({ network, ok: true, blockNumber });
        } catch (err) {
          statuses.push({
            network,
            ok: false,
            error: (err as Error).message
          });
        }
      };

      await check("l1");
      await check("l2");

      setStatus(statuses);
    };

    void load();
    const interval = setInterval(load, 5000);

    return () => clearInterval(interval);
  }, [networks]);

  return status;
};
