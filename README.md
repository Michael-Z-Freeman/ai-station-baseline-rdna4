# AI Station Baseline: ROCm 7.2.2 + RDNA 4 (RX 9060 XT)

### **Featured Model: Qwen2.5-Coder-32B-Instruct**
It is highly impressive that this **32.7 Billion parameter** state-of-the-art coding model runs stably on a **16GB VRAM** card. 
- **Quantization**: Q4_K_M (~19GB)
- **Status**: **Stable & Coherent**
- **Current Offloading**: **45 of 65 layers** on GPU (remaining 20 on CPU)
- **TurboQuant Magic**: Uses 2-bit KV Cache (`turbo2`) to shrink a 128k context window to only ~4.2GB, making this 32B model fit comfortably within 16GB VRAM.

## Core Repository
- **Optimized Backend**: [Michael-Z-Freeman/llama-cpp-turboquant](https://github.com/Michael-Z-Freeman/llama-cpp-turboquant) (Force-synced to verified baseline)

## 1. Critical Build Resolution (ROCm Issue #5826)
The key to getting RDNA 4 (`gfx1200`) working with ROCm 7.2.2 is forcing the **`-O3`** optimization level for HIP. 
- **The Problem**: Lower optimization levels (like `-O0`) trigger a compiler bug that generates illegal "wavefront shift" instructions unsupported on modern GFX10+ architectures.
- **Reference**: [ROCm Issue #5826 - wavefront shifts not supported on GFX10+](https://github.com/ROCm/ROCm/issues/5826)
- **The Fix**: Explicitly pass `-DCMAKE_HIP_FLAGS_RELEASE="-O3 -DNDEBUG"` during configuration.

## 2. ROCm 7.2.2 Installation
To support RDNA 4 (gfx1200), ROCm 7.2.2+ is required.
- **Repository**: `https://repo.radeon.com/rocm/apt/7.2.2 noble main`
- **Apt Pinning**: Priority 1001 for `origin repo.radeon.com` to allow necessary downgrades on Ubuntu 26.04.

## 3. System Compatibility Fixes
- **Tool Symlinks**: 
  - `ln -sf /opt/rocm-7.2.2/bin/hipcc /usr/bin/hipcc`
  - `ln -sf /opt/rocm-7.2.2/bin/hipconfig /usr/bin/hipconfig`
- **Library Compatibility**: `libxml2.so.2` compatibility link for Ubuntu 26.04:
  - `sudo ln -s /usr/lib/x86_64-linux-gnu/libxml2.so.16 /usr/lib/x86_64-linux-gnu/libxml2.so.2`

## 4. Llama-cpp-turboquant Build Command
```bash
HIPCXX="$(hipconfig -l)/clang" HIP_PATH="$(hipconfig -R)" \
    cmake -S . -B build -DGGML_HIP=ON -DGPU_TARGETS=gfx1200 \
    -DGGML_HIP_ROCWMMA_FATTN=ON -DGGML_HIP_MMQ_MFMA=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_HIP_FLAGS_RELEASE="-O3 -DNDEBUG" \
    && cmake --build build --config Release -- -j$(nproc)
```

## 5. Model Acquisition
```bash
HF_HUB_ENABLE_HF_TRANSFER=1 uvx --with hf_transfer hf download bartowski/Qwen2.5-Coder-32B-Instruct-GGUF \
    --local-dir models \
    --include "*Q4_K_M.gguf" \
    --max-workers 16
```
