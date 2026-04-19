# AI Station Baseline: ROCm 7.2.2 + RDNA 4 (RX 9060 XT)

### **Featured Model: Google Gemma-3-27B-It (3-bit Q3_K_M)**
This is a **"Direct Reasoning"** configuration. Released in February 2025, it is a Native Multimodal model that incorporates its logic directly into its high-speed output.

- **Quantization**: Q3_K_M (~13GB)
- **Status**: **100% GPU Offloaded (63/63 layers)**
- **Performance**: **~17 tokens/sec** (Generation), **~480 tokens/sec** (Prompt)
- **Context Window**: **32,768 tokens**
- **TurboQuant Magic**: Uses 3-bit KV Cache (`turbo3`) for near-lossless memory quality on 16GB VRAM.

## Core Repository
- **Optimized Backend**: [Michael-Z-Freeman/llama-cpp-turboquant](https://github.com/Michael-Z-Freeman/llama-cpp-turboquant)

## 1. Critical Build Resolution (ROCm Issue #5826)
Forced **`-O3`** optimization for HIP to bypass RDNA 4 (`gfx1200`) compiler bugs.
- **Fix**: `-DCMAKE_HIP_FLAGS_RELEASE="-O3 -DNDEBUG"`

## 2. Optimized Configuration (16GB VRAM / 14GB RAM)
- **Memory Fix**: `--cache-ram 0` (Prevents system lag).
- **Reasoning Style**: **Native/Implicit**. No explicit tags required. For step-by-step logic, simply prompt: *"Reason through this problem before answering."*
- **Launcher Script**: `~/bin/run_llama_simple.sh` (Optimized for stability).

## 3. Model Acquisition
```bash
HF_HUB_ENABLE_HF_TRANSFER=1 HF_TOKEN="your_token" uvx --with hf_transfer hf download unsloth/gemma-3-27b-it-GGUF \
    --local-dir models \
    --include "*Q3_K_M.gguf" \
    --max-workers 16
```
