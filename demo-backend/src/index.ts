import express from "express";
import cors from "cors";
import { config } from "./config.js";
import { DemoStore } from "./services/demoStore.js";
import { DemoRunner } from "./services/demoRunner.js";
import { createDemoRoutes } from "./routes/demoRoutes.js";
import { createConfigRoutes } from "./routes/configRoutes.js";

const app = express();
const store = new DemoStore();
const runner = new DemoRunner(store);

app.use(cors());
app.use(express.json({ limit: "1mb" }));

app.get("/health", (_req, res) => {
  res.json({ ok: true, time: new Date().toISOString() });
});

app.use("/demo", createDemoRoutes(runner, store));
app.use("/config", createConfigRoutes());

app.listen(config.port, () => {
  console.log(`[demo-backend] running on port ${config.port}`);
});
