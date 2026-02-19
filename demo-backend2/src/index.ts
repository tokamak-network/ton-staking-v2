import express from "express";
import cors from "cors";
import { config } from "./config.js";
import { createInteractiveRoutes } from "./routes/interactiveRoutes.js";

const app = express();

app.use(cors());
app.use(express.json({ limit: "1mb" }));

// Health check
app.get("/health", (_req, res) => {
  res.json({ 
    ok: true, 
    time: new Date().toISOString(),
    service: "demo-backend2 - Interactive Challenger Demo"
  });
});

// Interactive game routes
app.use("/api/game", createInteractiveRoutes());

// Error handling
app.use((err: any, req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error("[Error]", err);
  res.status(500).json({ error: err.message || "Internal server error" });
});

// Start server
app.listen(config.port, () => {
  console.log(`╔══╗`);
  console.log(`║  demo-backend2 - Interactive Challenger ║`);
  console.log(`╚══╝`);
  console.log(`🚀 Server running on port ${config.port}`);
  console.log(`📡 Health check: http://localhost:${config.port}/health`);
  console.log(`🎮 API endpoint: http://localhost:${config.port}/api/game`);
  console.log(`\nPress Ctrl+C to stop`);
});
