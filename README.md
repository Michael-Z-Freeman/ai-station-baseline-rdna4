# AI Station Baseline: ROCm 7.2.2 + RDNA 4 (RX 9060 XT)

<img width="2053" height="1601" alt="59b3c116-2653-4d50-9b5f-1fefd24a61bf" src="https://github.com/user-attachments/assets/32c6ce65-aa98-47a1-9e00-802a28eb0021" />

## **Current Milestone: Qwen2.5-Coder-14B-Instruct (Native TurboQuant 4-bit)**
This configuration represents a significant breakthrough in coding performance. By leveraging the **Native TurboQuant** mode, this 14.7B parameter model is fully offloaded to the 16GB GPU with room for a large context window. It successfully handles complex tasks like Three.js visualisations that previously failed on other models. However that comes with some caveats. In my tests the model fell down on some simple Three.js library calling in Open WebUI. But when I tested using Qwen Coder CLI the model accurately called the libraries. Qwen Coder has some issues though like a large amount of unresolved bugs on its GitHub repo. Also tool calling is broken for local models. But all things considered I've found this to be very productive research. It's amazing any of this works on a 16GB GPU. Imagine what an be achieved on a 128GB shared memory machine wikth Turbo Quant.

- **Quantization**: TQ4_1S (Pure Config-I) ~8.7GB
- **Status**: **100% GPU Offloaded (49/49 layers)**
- **Performance**: High-speed native generation.
- **Context Window**: **32,768 tokens** (TurboQuant 4-bit KV Cache)
- **TurboQuant Fix**: Uses `GGML_TQ_NATIVE=1` to prevent automatic 8-bit ballooning in VRAM.

---

## **Previous Baseline: Google Gemma-3-27B-It (3-bit Q3_K_M)**
- **Quantization**: Q3_K_M (~13GB)
- **Status**: **100% GPU Offloaded (63/63 layers)**
- **Performance**: ~17 tokens/sec (Generation)
- **TurboQuant Magic**: Used 3-bit KV Cache (`turbo3`) to fit on 16GB VRAM.

---

## Core Repository
- **Optimized Backend**: [Michael-Z-Freeman/llama-cpp-turboquant](https://github.com/Michael-Z-Freeman/llama-cpp-turboquant)

## 1. Technical Resolution History

### **Build Resolution (ROCm Issue #5826)**
Forced **`-O3`** optimization for HIP to bypass RDNA 4 (`gfx1200`) compiler bugs.
- **Fix**: `-DCMAKE_HIP_FLAGS_RELEASE="-O3 -DNDEBUG"`

### **VRAM Optimization (TurboQuant Native)**
Discovered that the backend defaults to decompressing TQ4 models to 8-bit during load.
- **Fix**: `export GGML_TQ_NATIVE=1` (Disables dequantization, saving ~4GB VRAM).

### **Quantization Integrity**

### **Note on Calibration & Importance Matrix (imatrix)**
Standard `llama.cpp` quants (like `IQ4_XS` or `Q4_K_M`) benefit from `imatrix` calibration to reduce perplexity loss. However, for this **TurboQuant** fork using `TQ4_1S` (Config-I):
- **Skipped imatrix**: The `TQ4_1S` quantization algorithm uses a fixed iterative refinement process that does not currently utilize external importance data.
- **Native Robustness**: The built-in Walsh-Hadamard Transform (WHT) rotation makes the model naturally robust to quantization errors without per-tensor calibration.
Standard quantization often leaves large tensors in F32/F16.
- **Fix**: Use `--pure` flag during `llama-quantize` to force all tensors into the 4-bit domain.

---

## 2. Used Commands (Qwen2.5-Coder Milestone)

### Model Acquisition & Conversion
```bash
# 1. Download Official Weights
HF_HUB_ENABLE_HF_TRANSFER=1 HF_TOKEN="your_token" uvx --with hf_transfer hf download Qwen/Qwen2.5-Coder-14B-Instruct --local-dir models/Qwen2.5-Coder-14B-Instruct --max-workers 16

# 2. Convert to GGUF F16 (using uv for dependencies)
uv run --with transformers --with torch --with numpy --with sentencepiece --with gguf \
  python3 convert_hf_to_gguf.py models/Qwen2.5-Coder-14B-Instruct/ \
  --outfile models/Qwen2.5-Coder-14B-Instruct-F16.gguf

# 3. Quantize to TurboQuant 4-bit (Pure)
./build/bin/llama-quantize --pure \
  models/Qwen2.5-Coder-14B-Instruct-F16.gguf \
  models/Qwen2.5-Coder-14B-Instruct-TQ4_PURE.gguf \
  TQ4_1S
```

### System Launch Configuration
- **Update Environment** (`.config/ai-station.env`):
  ```bash
  AI_STATION_MODEL_PATH="/path/to/models/Qwen2.5-Coder-14B-Instruct-TQ4_PURE.gguf"
  AI_STATION_GPU_LAYERS=99
  export GGML_TQ_NATIVE=1
  ```

- **Update Launch Script** (`run_llama_simple.sh`):
  ```bash
  # Optimization for Qwen on TurboQuant fork:
  --cache-type-k q8_0 --cache-type-v turbo4
  ```

- **Open WebUI Maintenance**:
  ```bash
  # Update/Reinstall stable version
  uv pip install open-webui==0.8.12 --python /path/to/venv/bin/python3
  ```

---

## 3. Deployment & Automation

The project includes systemd service units and supporting bash scripts to manage the LLM stack. These are located in the `deploy/` directory and should be linked to their respective system locations.

### Systemd Services (`deploy/systemd/`)

#### **`llm-webui-stack.service`**
The primary orchestrator that manages both the backend and frontend as a unified stack.
```ini
[Unit]
Description=Local LLM + Open WebUI stack
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/home/michaelzfreeman/bin/start-llm-webui-stack.sh
WorkingDirectory=/home/michaelzfreeman
Restart=on-failure
RestartSec=5
StandardOutput=append:/home/michaelzfreeman/tmp/llm-webui-stack.log
StandardError=append:/home/michaelzfreeman/tmp/llm-webui-stack.err.log

[Install]
WantedBy=default.target
```

### Automation Scripts (`deploy/bin/`)

#### **`start-llm-webui-stack.sh`**
A robust wrapper that ensures `llama-server` is ready before launching the WebUI. It uses a FIFO pipe to keep the interactive server process active under systemd.
```bash
#!/usr/bin/env bash
set -euo pipefail

LLAMA_SCRIPT="/home/michaelzfreeman/Development/local-llm/llama-cpp-turboquant/run_llama_timed_prompt.sh"
WEBUI_SCRIPT="/home/michaelzfreeman/Installations/BitNet-M1-AI-Station/start_webui.sh"
# ... [See deploy/bin/start-llm-webui-stack.sh for full implementation]
```

#### **`run_llama_simple.sh`**
Optimized launcher for the TurboQuant backend using local environment configuration.
```bash
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
```

#### **`run_openwebui_simple.sh`**
Launcher for the Open WebUI frontend, managing virtualenv activation and environment variables.
```bash
#!/usr/bin/env bash
# Simplified Open WebUI launcher for AI Station
set -euo pipefail

# Load central configuration
source "${HOME}/.config/ai-station.env"

# Move to the Open WebUI directory
cd "$AI_STATION_WEBUI_DIR"

# Activate virtualenv
source .venv-webui/bin/activate

# Set environment variables for the process
export HOST="$AI_STATION_WEBUI_HOST"
export PORT="$AI_STATION_WEBUI_PORT"
export OPENAI_API_BASE_URL="http://${AI_STATION_LLAMA_HOST}:${AI_STATION_LLAMA_PORT}/v1"
export OPENAI_API_KEY="unused"
export DATA_DIR="$AI_STATION_WEBUI_DIR/data"

echo "Starting Open WebUI on ${AI_STATION_WEBUI_HOST}:${AI_STATION_WEBUI_PORT}..."

exec open-webui serve
```

## Qwen Function Calling Architecture

This project uses a three-way handshake to enable the AI model to interact with your local files and system.

### The Handshake Schematic

```text
┌────────────────────────────────┐          ┌──────────────────────────┐          ┌──────────────────────────┐
│      QWEN CLI AGENT            │          │      LLAMA-SERVER        │          │       QWEN MODEL         │
│      (Node.js App)             │          │      (llama.cpp)         │          │       (GGUF File)        │
├────────────────────────────────┤          ├──────────────────────────┤          ├──────────────────────────┤
│ 1. DEFINES TOOLS               │          │                          │          │                          │
│    (read_file, edit, etc.)     │─────────>│ 2. PASSES PROMPT         │─────────>│ 3. REASONS & DECIDES     │
│                                │          │    + TOOL SCHEMAS        │          │    "I need a tool!"      │
│                                │          │                          │          │                          │
│                                │          │                          │          │ 4. OUTPUTS TEXT:         │
│ 6. EXECUTES TOOL               │<─────────│ 5. THE TRANSLATOR        │<─────────│    "<tool_call>...      │
│    (Reads your actual hard     │          │    (The Parser)          │          │     JSON..."            │
│     drive via Node.js)         │          │                          │          └──────────────────────────┘
└──────────────┬─────────────────┘          └────────────┬─────────────┘
               │                                         │
               │                                         │
               ▼                                         ▼
    ┌────────────────────────┐                ┌────────────────────────┐
    │  CURRENT STATUS:       │                │  WHERE IT BREAKS:      │
    │  The Agent is IDLE     │                │  Server is NOT parsing │
    │  because it sees only  │                │  Step 4 text into the  │
    │  standard chat text.   │                │  OpenAI JSON field.    │
    └────────────────────────┘                └────────────────────────┘
```

### Handshake Component Breakdown

| Phase | Component | Action |
| :--- | :--- | :--- |
| **1. Define** | **CLI Agent** | Sends the user prompt plus tool "Schemas" (e.g., `read_file` requires a `file_path`). |
| **2. Decide** | **Qwen Model** | The model reasons through the prompt and decides to use a tool by outputting XML/JSON text. |
| **3. Translate**| **llama-server** | **(Crucial Step)** Intercepts the model's text and packages it into the OpenAI-standard `tool_calls` JSON field. |
| **4. Execute** | **CLI Agent** | Receives the `tool_calls` field and triggers its local Node.js code to read/write files or run shell commands. |
| **5. Return**  | **CLI Agent** | Sends the result (e.g., file contents) back to the model to complete the original request. |
