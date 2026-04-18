#!/usr/bin/env bash
# Simplified llama-server launcher for AI Station (TurboQuant Optimized)
set -euo pipefail

# Load central configuration
source "${HOME}/.config/ai-station.env"

# Ensure binary is executable
if [[ ! -x "$AI_STATION_LLAMA_BIN" ]]; then
  echo "Error: llama-server not executable at: $AI_STATION_LLAMA_BIN" >&2
  exit 1
fi

# Ensure model exists
if [[ ! -f "$AI_STATION_MODEL_PATH" ]]; then
  echo "Error: model not found at: $AI_STATION_MODEL_PATH" >&2
  exit 1
fi

echo "Starting llama-server (AI Station) on ${AI_STATION_LLAMA_HOST}:${AI_STATION_LLAMA_PORT}..."

# Hand over to llama-server binary with TurboQuant and memory fixes
exec "$AI_STATION_LLAMA_BIN" \
  -m "$AI_STATION_MODEL_PATH" \
  --host "$AI_STATION_LLAMA_HOST" \
  --port "$AI_STATION_LLAMA_PORT" \
  --ctx-size "$AI_STATION_CTX_SIZE" \
  --gpu-layers "$AI_STATION_GPU_LAYERS" \
  --jinja \
  --flash-attn on \
  --cache-type-k turbo2 \
  --cache-type-v turbo2 \
  --cache-ram 0 \
  --parallel 1
