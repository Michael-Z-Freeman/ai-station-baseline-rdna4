#!/usr/bin/env bash
# AI Station: Gemma-3-27B (Full TQ4 Lossless Optimized)
set -euo pipefail
source "${HOME}/.config/ai-station.env"

echo "Starting llama-server (Gemma-3 TQ4) on ${AI_STATION_LLAMA_HOST}:${AI_STATION_LLAMA_PORT}..."

exec "$AI_STATION_LLAMA_BIN" \
  -m "$AI_STATION_MODEL_PATH" \
  --host "$AI_STATION_LLAMA_HOST" \
  --port "$AI_STATION_LLAMA_PORT" \
  --ctx-size "$AI_STATION_CTX_SIZE" \
  --gpu-layers "$AI_STATION_GPU_LAYERS" \
  --jinja \
  --chat-template-kwargs '{"chat_format": "openai"}' \
  --flash-attn on \
  --cache-type-k q8_0 \
  --cache-type-v turbo4 \
  --cache-ram 0 \
  --temp 0.1 \
  --top-p 0.9 \
  --top-k 40 \
  --repeat-penalty 1.1 \
  --parallel 1
