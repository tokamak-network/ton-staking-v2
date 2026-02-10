#!/usr/bin/env node
const fs = require("fs");
const path = require("path");

const [,, contractName, outputPathArg] = process.argv;

if (!contractName || !outputPathArg) {
  console.error("Usage: node extract-abi.js <ContractName> <OutputPath>");
  process.exit(1);
}

const rootDir = path.resolve(__dirname, "../..");
const artifactsDir = path.join(rootDir, "artifacts");

if (!fs.existsSync(artifactsDir)) {
  console.error("Artifacts directory not found. Run `npx hardhat compile` first.");
  process.exit(1);
}

const outputPath = path.resolve(rootDir, outputPathArg);

const findArtifact = (dir) => {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      const result = findArtifact(fullPath);
      if (result) return result;
    }
    if (entry.isFile() && entry.name.endsWith(".json")) {
      const raw = fs.readFileSync(fullPath, "utf8");
      try {
        const data = JSON.parse(raw);
        if (data.contractName === contractName && Array.isArray(data.abi)) {
          return data.abi;
        }
      } catch (_) {}
    }
  }
  return null;
};

const abi = findArtifact(artifactsDir);

if (!abi) {
  console.error(`ABI not found for contract: ${contractName}`);
  process.exit(1);
}

fs.mkdirSync(path.dirname(outputPath), { recursive: true });
fs.writeFileSync(outputPath, JSON.stringify(abi, null, 2));
console.log(`[extract-abi] wrote ${outputPath}`);
