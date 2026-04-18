#!/usr/bin/env bash
# Simplified Open WebUI launcher for AI Station
set -euo pipefail

# Load central configuration
source "${HOME}/.config/ai-station.env"

# Move to the Open WebUI directory
cd "$AI_STATION_WEBUI_DIR"

# Apply hotfixes if script exists
if [[ -x "./scripts/patch_openwebui_serper.sh" ]]; then
  echo "Applying Open WebUI patches..."
  "./scripts/patch_openwebui_serper.sh"
fi

# Activate virtualenv
if [[ ! -f ".venv-webui/bin/activate" ]]; then
  echo "Error: virtualenv not found in $AI_STATION_WEBUI_DIR/.venv-webui" >&2
  exit 1
fi

source .venv-webui/bin/activate

# Set environment variables for the process
export HOST="$AI_STATION_WEBUI_HOST"
export PORT="$AI_STATION_WEBUI_PORT"
export OPENAI_API_BASE_URL="http://${AI_STATION_LLAMA_HOST}:${AI_STATION_LLAMA_PORT}/v1"
export OPENAI_API_KEY="unused"

echo "Starting Open WebUI on ${AI_STATION_WEBUI_HOST}:${AI_STATION_WEBUI_PORT}..."

# Hand over to open-webui binary
exec open-webui serve
