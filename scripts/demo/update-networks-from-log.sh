#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG_FILE="$ROOT_DIR/.devnet/devnet.log"
OUTPUT_FILE="$ROOT_DIR/demo-config/networks.json"

if [ ! -f "$LOG_FILE" ]; then
  echo "[update-networks] devnet log not found: $LOG_FILE"
  exit 1
fi

extract_ports() {
  {
    grep -E "endpoint=127.0.0.1:" "$LOG_FILE" || true
    grep -E "endpoint=http://127.0.0.1:" "$LOG_FILE" || true
    grep -E "endpoint=http://\\[::\\]:" "$LOG_FILE" || true
  } | sed -E 's/.*endpoint=127\.0\.0\.1:([0-9]+).*/\1/' \
    | sed -E 's/.*endpoint=http:\/\/127\.0\.0\.1:([0-9]+).*/\1/' \
    | sed -E 's/.*endpoint=http:\/\/\\[::\\]:([0-9]+).*/\1/' \
    | grep -E '^[0-9]+$' || true
}

probe_chain_id() {
  local port=$1
  local resp
  resp=$(curl -s -X POST "http://127.0.0.1:${port}" \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' || true)
  echo "$resp" | grep -o '"result":"0x[0-9a-fA-F]\+"' | sed -E 's/.*"result":"(0x[0-9a-fA-F]+)".*/\1/' || true
}

L1_PORT=""
L2_PORT=""

for i in {1..60}; do
  ports=$(extract_ports | sort -u)
  if [ -z "$ports" ]; then
    echo "[update-networks] no ports found yet (try $i)"
    sleep 1
    continue
  fi

  echo "[update-networks] candidate ports: $ports"

  for port in $ports; do
    chain=$(probe_chain_id "$port")
    if [ -n "$chain" ]; then
      echo "[update-networks] port $port chainId=$chain"
    fi
    if [ "$chain" = "0x384" ]; then # 900
      L1_PORT=$port
    fi
    if [ "$chain" = "0x385" ]; then # 901
      L2_PORT=$port
    fi
  done

  if [ -n "$L1_PORT" ] && [ -n "$L2_PORT" ]; then
    break
  fi
  sleep 1
done

if [ -z "$L1_PORT" ] || [ -z "$L2_PORT" ]; then
  echo "[update-networks] failed to detect L1/L2 ports"
  echo "  L1_PORT=$L1_PORT"
  echo "  L2_PORT=$L2_PORT"
  exit 1
fi

cat > "$OUTPUT_FILE" <<EOF
{
  "l1": {
    "chainId": 900,
    "rpcUrl": "http://127.0.0.1:${L1_PORT}"
  },
  "l2": {
    "chainId": 901,
    "rpcUrl": "http://127.0.0.1:${L2_PORT}"
  },
  "opNode": "http://127.0.0.1:9546",
  "batcher": "http://127.0.0.1:8548"
}
EOF

echo "[update-networks] updated networks.json"
echo "  L1: http://127.0.0.1:${L1_PORT}"
echo "  L2: http://127.0.0.1:${L2_PORT}"
