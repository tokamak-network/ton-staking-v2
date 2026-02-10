import { Router } from "express";
import { z } from "zod";
import { DemoRunner } from "../services/demoRunner.js";
import { DemoStore } from "../services/demoStore.js";

export const createDemoRoutes = (runner: DemoRunner, store: DemoStore) => {
  const router = Router();

  router.post("/start", (req, res) => {
    const schema = z.object({
      scenarioKey: z.string()
    });
    const body = schema.parse(req.body);
    const run = runner.startScenario(body.scenarioKey);
    res.json(run);
  });

  router.post("/stop/:id", (req, res) => {
    const runId = req.params.id;
    const stopped = runner.stopScenario(runId);
    res.json({ stopped });
  });

  router.get("/status/:id", (req, res) => {
    const run = store.getRun(req.params.id);
    if (!run) return res.status(404).json({ error: "Not found" });
    res.json(run);
  });

  router.get("/logs/:id", (req, res) => {
    const run = store.getRun(req.params.id);
    if (!run) return res.status(404).json({ error: "Not found" });
    res.json({ logs: run.logs });
  });

  router.get("/runs", (_req, res) => {
    res.json(store.listRuns());
  });

  return router;
};
