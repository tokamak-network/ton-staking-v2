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
const outputPath = path.resolve(rootDir, outputPathArg);

const findArtifact = (dir) => {
  if (!fs.existsSync(dir)) return null;
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

const extractAbiFromGo = (fileContent) => {
  const doubleQuoteRegex = new RegExp(
    `${contractName}MetaData\\s*=\\s*&bind\\.MetaData\\{[^}]*ABI:\\s*"((?:\\\\.|[^"])*)"`,
    "s"
  );
  const backtickRegex = new RegExp(
    `${contractName}MetaData\\s*=\\s*&bind\\.MetaData\\{[^}]*ABI:\\s*\`([\\s\\S]*?)\``,
    "s"
  );

  let match = fileContent.match(doubleQuoteRegex);
  if (match && match[1]) {
    const raw = match[1];
    const decoded = JSON.parse(`"${raw}"`);
    return JSON.parse(decoded);
  }

  match = fileContent.match(backtickRegex);
  if (match && match[1]) {
    return JSON.parse(match[1]);
  }

  return null;
};

const findGoAbi = (dir) => {
  if (!fs.existsSync(dir)) return null;
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      const result = findGoAbi(fullPath);
      if (result) return result;
    }
    if (entry.isFile() && entry.name.endsWith(".go")) {
      const content = fs.readFileSync(fullPath, "utf8");
      if (!content.includes(`${contractName}MetaData`)) continue;
      const abi = extractAbiFromGo(content);
      if (abi) return abi;
    }
  }
  return null;
};

let abi = findArtifact(artifactsDir);

if (!abi) {
  const optimismDir = path.join(rootDir, "lib/optimism");
  abi = findGoAbi(optimismDir);
}

if (!abi) {
  console.error(`ABI not found for contract: ${contractName}`);
  process.exit(1);
}

fs.mkdirSync(path.dirname(outputPath), { recursive: true });
fs.writeFileSync(outputPath, JSON.stringify(abi, null, 2));
console.log(`[extract-abi] wrote ${outputPath}`);
