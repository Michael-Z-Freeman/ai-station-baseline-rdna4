# AI Station Baseline: ROCm 7.2.2 + RDNA 4 (RX 9060 XT)

<img width="2053" height="1601" alt="59b3c116-2653-4d50-9b5f-1fefd24a61bf" src="https://github.com/user-attachments/assets/32c6ce65-aa98-47a1-9e00-802a28eb0021" />

## **Current Milestone: Qwen2.5-Coder-14B-Instruct (Native TurboQuant 4-bit)**
This configuration represents a significant breakthrough in coding performance. By leveraging the **Native TurboQuant** mode, this 14.7B parameter model is fully offloaded to the 16GB GPU with room for a large context window. It successfully handles complex tasks like Three.js visualisations that previously failed on other models.

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
