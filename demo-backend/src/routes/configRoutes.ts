import { Router } from "express";
import { config } from "../config.js";
import { readJsonFile } from "../utils/fs.js";
import { DemoScenario } from "../types.js";

interface ScenarioConfig {
  scenarios: DemoScenario[];
}

export const createConfigRoutes = () => {
  const router = Router();

  router.get("/deployments", (_req, res) => {
    const data = readJsonFile<Record<string, string>>(config.deploymentsPath);
    res.json(data);
  });

  router.get("/scenarios", (_req, res) => {
    const data = readJsonFile<ScenarioConfig>(config.scenariosPath);
    res.json(data);
  });

  router.get("/challengers", (_req, res) => {
    const data = readJsonFile<Record<string, unknown>>(config.challengersPath);
    res.json(data);
  });

  router.get("/networks", (_req, res) => {
    const data = readJsonFile<Record<string, unknown>>(config.networksPath);
    res.json(data);
  });

  router.get("/events", (_req, res) => {
    const data = readJsonFile<Record<string, unknown>>(config.eventsPath);
    res.json(data);
  });

  return router;
};
