#!/usr/bin/env bash
set -euo pipefail

LLAMA_SCRIPT="/home/michaelzfreeman/Development/local-llm/llama-cpp-turboquant/run_llama_timed_prompt.sh"
WEBUI_SCRIPT="/home/michaelzfreeman/Installations/BitNet-M1-AI-Station/start_webui.sh"
WEBUI_DIR="$(dirname "$WEBUI_SCRIPT")"
LLAMA_HOST="${LLAMA_HOST:-127.0.0.1}"
LLAMA_PORT="${LLAMA_PORT:-8081}"
READY_URL="http://${LLAMA_HOST}:${LLAMA_PORT}/v1/models"
LLAMA_READY_TIMEOUT_SECS="${LLAMA_READY_TIMEOUT_SECS:-180}"

if [[ ! -x "$LLAMA_SCRIPT" ]]; then
  echo "Error: llama startup script is not executable: $LLAMA_SCRIPT" >&2
  exit 1
fi

if [[ ! -x "$WEBUI_SCRIPT" ]]; then
  echo "Error: Open WebUI startup script is not executable: $WEBUI_SCRIPT" >&2
  exit 1
fi

# run_llama_timed_prompt.sh is interactive; we keep stdin open with a FIFO and
# write /status periodically so the process stays alive under systemd.
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
FIFO_PATH="${RUNTIME_DIR}/llama-timed-input.fifo"
rm -f "$FIFO_PATH"
mkfifo "$FIFO_PATH"

cleanup() {
  rm -f "$FIFO_PATH"
}
trap cleanup EXIT

{
  while true; do
    printf '/status\n'
    sleep 300
  done
} > "$FIFO_PATH" &
FEEDER_PID=$!

"$LLAMA_SCRIPT" < "$FIFO_PATH" &
LLAMA_WRAPPER_PID=$!

ready=0
for ((i=0; i<LLAMA_READY_TIMEOUT_SECS; i++)); do
  if curl -sSf "$READY_URL" >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 1
done

if [[ "$ready" -ne 1 ]]; then
  echo "Error: llama-server did not become ready at $READY_URL within ${LLAMA_READY_TIMEOUT_SECS}s" >&2
  kill "$FEEDER_PID" "$LLAMA_WRAPPER_PID" >/dev/null 2>&1 || true
  wait "$FEEDER_PID" "$LLAMA_WRAPPER_PID" >/dev/null 2>&1 || true
  exit 1
fi

(
  cd "$WEBUI_DIR"
  "$WEBUI_SCRIPT"
) &
WEBUI_PID=$!

wait -n "$WEBUI_PID" "$LLAMA_WRAPPER_PID"
exit_code=$?

kill "$FEEDER_PID" >/dev/null 2>&1 || true
wait "$FEEDER_PID" >/dev/null 2>&1 || true

exit "$exit_code"
