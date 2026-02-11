import { Router } from "express";
import { spawn, execSync } from "child_process";
import path from "path";
import fs from "fs";
import { config } from "../config.js";

let sessionPid: number | null = null;

const sessionDir = path.join(config.rootDir, ".demo");
const statePath = path.join(sessionDir, "session.json");
const commandPath = path.join(sessionDir, "command.json");
const logPath = path.join(sessionDir, "session.log");

const resolveGoBin = () => {
  if (process.env.GO_BIN) {
    return process.env.GO_BIN;
  }
  try {
    const output = execSync("command -v go").toString().trim();
    return output;
  } catch {
    return null;
  }
};

const safeUnlink = (filePath: string) => {
  if (fs.existsSync(filePath)) {
    fs.unlinkSync(filePath);
  }
};

const clearSessionArtifacts = () => {
  safeUnlink(statePath);
  safeUnlink(commandPath);
  safeUnlink(logPath);
};

export const createSessionRoutes = () => {
  const router = Router();

  router.post("/start", (req, res) => {
    if (sessionPid) {
      return res.json({ ok: true, pid: sessionPid, message: "already running" });
    }

    const goBin = resolveGoBin();
    if (!goBin) {
      return res.status(500).json({ error: "go binary not found. Set GO_BIN or ensure go is in PATH." });
    }

    const mode = req.body?.mode ?? "single";

    fs.mkdirSync(sessionDir, { recursive: true });
    fs.writeFileSync(logPath, "");

    const child = spawn(goBin, ["test", "-v", "-count=1", "-timeout", "24h", "-run", "TestDemoSession", "./slashing/..."], {
      cwd: path.join(config.rootDir, "op-e2e"),
      env: { ...process.env, DEMO_MODE: mode }
    });

    sessionPid = child.pid ?? null;

    const appendLog = (data: Buffer) => {
      fs.appendFileSync(logPath, data.toString());
    };

    child.stdout.on("data", appendLog);
    child.stderr.on("data", appendLog);

    child.on("exit", (code) => {
      sessionPid = null;
      fs.appendFileSync(logPath, `\n[session] exited with code ${code}\n`);
    });

    res.json({ ok: true, pid: sessionPid, mode });
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

  router.get("/logs", (_req, res) => {
    if (!fs.existsSync(logPath)) {
      return res.json({ logs: "" });
    }
    const data = fs.readFileSync(logPath, "utf8");
    res.json({ logs: data });
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

  router.post("/reset", (_req, res) => {
    if (sessionPid) {
      try {
        process.kill(sessionPid, "SIGTERM");
      } catch {}
      sessionPid = null;
    }
    fs.mkdirSync(sessionDir, { recursive: true });
    clearSessionArtifacts();
    res.json({ ok: true });
  });

  return router;
};
