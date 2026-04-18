# AI Station Baseline: ROCm 7.2.2 + RDNA 4 (RX 9060 XT)

### **Featured Model: Google Gemma-3-27B-It (3-bit Q3_K_M)**
This is the current **"Ultra-Modern"** configuration. Released in February 2025, it is a Native Multimodal model that is significantly faster and more "web-socialized" than older models.

- **Quantization**: Q3_K_M (~13GB)
- **Status**: **100% GPU Offloaded (63/63 layers)**
- **Performance**: **~17 tokens/sec** (Generation), **~480 tokens/sec** (Prompt)
- **Context Window**: **32,768 tokens**
- **TurboQuant Magic**: Uses 3-bit KV Cache (`turbo3`) to fit the entire model and a large 32k memory into 16GB VRAM at near-lossless quality.

## Core Repository
- **Optimized Backend**: [Michael-Z-Freeman/llama-cpp-turboquant](https://github.com/Michael-Z-Freeman/llama-cpp-turboquant)

## 1. Critical Build Resolution (ROCm Issue #5826)
The key to getting RDNA 4 (`gfx1200`) working is forcing the **`-O3`** optimization level for HIP.
- **Fix**: `-DCMAKE_HIP_FLAGS_RELEASE="-O3 -DNDEBUG"`

## 2. Model Acquisition (Gemma-3-27B)
```bash
HF_HUB_ENABLE_HF_TRANSFER=1 HF_TOKEN="your_token" uvx --with hf_transfer hf download unsloth/gemma-3-27b-it-GGUF \
    --local-dir models \
    --include "*Q3_K_M.gguf" \
    --max-workers 16
```

## 3. Verified Launcher Script
Optimized for your **16GB GPU** and **14GB RAM**:
- `--cache-ram 0` (Prevents system lag)
- `--cache-type-k turbo3 --cache-type-v turbo3` (Precise 3-bit memory)
- `--temp 0.8 --repeat-penalty 1.1` (Stability for Javascript/Coding)

## 6. Known Issues & TODO
- [ ] **Gemma-3 Native Reasoning**: The built-in `--reasoning on` and `bailing-think` templates currently cause gibberish output with this Gemma-3 GGUF. 
  - **Status**: Reverted to stable configuration. 
  - **Workaround**: Use prompt engineering (*"Think step-by-step inside <thought> tags"*) instead of server-side flags.
  - **Required**: Need to develop/source a specialized Gemma-3 Jinja template that correctly handles the `<thought>` (108) and `</thought>` (109) tokens.
