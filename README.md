# AI Station Baseline: ROCm 7.2.2 + RDNA 4 (RX 9060 XT)

### **Featured Model: DeepSeek-R1-Distill-Qwen-32B (3-bit IQ3_M)**
This is the current "Perfect Fit" configuration for a 16GB VRAM card. It runs a state-of-the-art **2025 Reasoning model** at full hardware speed.

- **Quantization**: IQ3_M (~13.5GB)
- **Status**: **100% GPU Offloaded (65/65 layers)**
- **Performance**: **~30-40 tokens/sec**
- **Context Window**: **32,768 tokens** (expandable to 128k)
- **TurboQuant Magic**: Uses 2-bit KV Cache (`turbo2`) to fit the entire model and memory into 16GB VRAM, leaving the CPU completely free for system tasks.

## Core Repository
- **Optimized Backend**: [Michael-Z-Freeman/llama-cpp-turboquant](https://github.com/Michael-Z-Freeman/llama-cpp-turboquant) (Force-synced to verified baseline)

## 1. Critical Build Resolution (ROCm Issue #5826)
The key to getting RDNA 4 (`gfx1200`) working with ROCm 7.2.2 is forcing the **`-O3`** optimization level for HIP to bypass illegal instruction bugs.
- **Reference**: [ROCm Issue #5826](https://github.com/ROCm/ROCm/issues/5826)
- **Fix**: `-DCMAKE_HIP_FLAGS_RELEASE="-O3 -DNDEBUG"`

## 2. Optimized Configuration (16GB VRAM / 14GB RAM)
To prevent system lag, the "Prompt Cache" in RAM is disabled to ensure the CPU isn't overwhelmed.
- **Key Flags**: `--cache-ram 0 --cache-type-k turbo2 --cache-type-v turbo2 --flash-attn on`

## 3. Model Acquisition (DeepSeek-R1-32B)
```bash
HF_HUB_ENABLE_HF_TRANSFER=1 uvx --with hf_transfer hf download bartowski/DeepSeek-R1-Distill-Qwen-32B-GGUF \
    --local-dir models \
    --include "*IQ3_M.gguf" \
    --max-workers 16
```

## 4. Build Command
```bash
HIPCXX="$(hipconfig -l)/clang" HIP_PATH="$(hipconfig -R)" \
    cmake -S . -B build -DGGML_HIP=ON -DGPU_TARGETS=gfx1200 \
    -DGGML_HIP_ROCWMMA_FATTN=ON -DGGML_HIP_MMQ_MFMA=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_HIP_FLAGS_RELEASE="-O3 -DNDEBUG" \
    && cmake --build build --config Release -- -j$(nproc)
```
