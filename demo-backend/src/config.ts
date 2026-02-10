import path from "path";
import dotenv from "dotenv";

dotenv.config();

const resolveRoot = () => {
  if (process.env.DEMO_ROOT_DIR) {
    return path.resolve(process.env.DEMO_ROOT_DIR);
  }
  return path.resolve(process.cwd(), "..");
};

const rootDir = resolveRoot();

export const config = {
  port: Number(process.env.PORT ?? 4000),
  rootDir,
  deploymentsPath: process.env.DEMO_DEPLOYMENTS_PATH
    ? path.resolve(process.env.DEMO_DEPLOYMENTS_PATH)
    : path.join(rootDir, "deployments/v3-devnet-slashing.json"),
  scenariosPath: process.env.DEMO_SCENARIOS_PATH
    ? path.resolve(process.env.DEMO_SCENARIOS_PATH)
    : path.join(rootDir, "demo-config/scenarios.json"),
  challengersPath: process.env.DEMO_CHALLENGERS_PATH
    ? path.resolve(process.env.DEMO_CHALLENGERS_PATH)
    : path.join(rootDir, "demo-config/challengers.json"),
  networksPath: process.env.DEMO_NETWORKS_PATH
    ? path.resolve(process.env.DEMO_NETWORKS_PATH)
    : path.join(rootDir, "demo-config/networks.json"),
  scriptBase: process.env.DEMO_SCRIPT_BASE
    ? path.resolve(process.env.DEMO_SCRIPT_BASE)
    : rootDir
};
