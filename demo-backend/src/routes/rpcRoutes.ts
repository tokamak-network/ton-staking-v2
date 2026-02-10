import { Router } from "express";
import { readJsonFile } from "../utils/fs.js";
import { config } from "../config.js";

export const createRpcRoutes = () => {
  const router = Router();

  router.post("/:network", async (req, res) => {
    const network = req.params.network;
    const networks = readJsonFile<Record<string, { rpcUrl?: string }>>(config.networksPath);
    const rpcUrl = networks?.[network]?.rpcUrl;

    if (!rpcUrl) {
      return res.status(400).json({ error: `RPC not configured for ${network}` });
    }

    try {
      const response = await fetch(rpcUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(req.body)
      });

      const data = await response.text();
      res.status(response.status).send(data);
    } catch (err) {
      const message = (err as Error).message || "fetch failed";
      console.error(`[rpc proxy] ${network} -> ${rpcUrl} failed: ${message}`);
      res.status(500).json({
        error: `fetch failed: ${message}`,
        network,
        rpcUrl
      });
    }
  });

  return router;
};
