import { Router } from "express";
import { spawn } from "child_process";
import path from "path";
import fs from "fs";
import { config } from "../config.js";

let sessionPid: number | null = null;

const sessionDir = path.join(config.rootDir, ".demo");
const statePath = path.join(sessionDir, "session.json");
const commandPath = path.join(sessionDir, "command.json");

export const createSessionRoutes = () => {
  const router = Router();

  router.post("/start", (_req, res) => {
    if (sessionPid) {
      return res.json({ ok: true, pid: sessionPid, message: "already running" });
    }

    fs.mkdirSync(sessionDir, { recursive: true });

    const child = spawn("bash", ["-lc", "go test -v -timeout 24h -run TestDemoSession ./slashing/..."], {
      cwd: path.join(config.rootDir, "op-e2e"),
      env: process.env
    });

    sessionPid = child.pid ?? null;

    child.on("exit", () => {
      sessionPid = null;
    });

    res.json({ ok: true, pid: sessionPid });
  });

  router.post("/slash", (_req, res) => {
    fs.mkdirSync(sessionDir, { recursive: true });
    fs.writeFileSync(commandPath, JSON.stringify({ action: "slash" }, null, 2));
    res.json({ ok: true });
  });

  router.get("/state", (_req, res) => {
    if (!fs.existsSync(statePath)) {
      return res.status(404).json({ error: "state not found" });
    }
    const data = fs.readFileSync(statePath, "utf8");
    res.send(data);
  });

  router.post("/stop", (_req, res) => {
    if (sessionPid) {
      try {
        process.kill(sessionPid, "SIGTERM");
      } catch {}
      sessionPid = null;
    }
    res.json({ ok: true });
  });

  return router;
};
