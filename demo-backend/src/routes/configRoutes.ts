import { Router } from "express";
import { config } from "../config.js";
import { readJsonFile } from "../utils/fs.js";
import { DemoScenario } from "../types.js";
import fs from "fs";
import path from "path";

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

  router.get("/abis", (_req, res) => {
    const files = fs.existsSync(config.abisDir)
      ? fs.readdirSync(config.abisDir).filter((f) => f.endsWith(".json"))
      : [];
    res.json({ files });
  });

  router.get("/abi/:name", (req, res) => {
    const fileName = `${req.params.name}.json`;
    const filePath = path.join(config.abisDir, fileName);
    if (!fs.existsSync(filePath)) {
      return res.status(404).json({ error: "ABI not found" });
    }
    const data = readJsonFile<Record<string, unknown>>(filePath);
    res.json(data);
  });

  router.get("/abi/:name/events", (req, res) => {
    const fileName = `${req.params.name}.json`;
    const filePath = path.join(config.abisDir, fileName);
    if (!fs.existsSync(filePath)) {
      return res.status(404).json({ error: "ABI not found" });
    }
    const data = readJsonFile<any[]>(filePath);
    const events = data
      .filter((item) => item.type === "event")
      .map((item) => item.name);
    res.json({ events });
  });

  return router;
};
