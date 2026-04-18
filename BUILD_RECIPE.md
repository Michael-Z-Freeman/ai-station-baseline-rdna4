# AI Station: RDNA 4 (RX 9060 XT) Build Recipe

## 1. ROCm 7.2.2 Installation
To support RDNA 4 (gfx1200), ROCm 7.2.2+ is required.
- **Repository**: `https://repo.radeon.com/rocm/apt/7.2.2 noble main`
- **Apt Pinning**: Priority 1001 for `origin repo.radeon.com` to allow necessary downgrades on Ubuntu 26.04.

## 2. System Compatibility Fixes
- **Tool Symlinks**: 
  - `ln -sf /opt/rocm-7.2.2/bin/hipcc /usr/bin/hipcc`
  - `ln -sf /opt/rocm-7.2.2/bin/hipconfig /usr/bin/hipconfig`
- **Library Compatibility**: `libxml2.so.2` is required by the ROCm linker but missing on Ubuntu 26.04.
  - `sudo ln -s /usr/lib/x86_64-linux-gnu/libxml2.so.16 /usr/lib/x86_64-linux-gnu/libxml2.so.2`

## 3. Llama-cpp-turboquant Build Command
The `-O3` flag for HIP is critical to bypass a compiler bug that generates illegal instructions (wavefront shifts) for GFX10+ on lower optimization levels.

```bash
HIPCXX="$(hipconfig -l)/clang" HIP_PATH="$(hipconfig -R)" \
    cmake -S . -B build -DGGML_HIP=ON -DGPU_TARGETS=gfx1200 \
    -DGGML_HIP_ROCWMMA_FATTN=ON -DGGML_HIP_MMQ_MFMA=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_HIP_FLAGS_RELEASE="-O3 -DNDEBUG" \
    && cmake --build build --config Release -- -j$(nproc)
```

## 4. Current Model Baseline
- **Model**: Qwen2.5-Coder-32B-Instruct-Q4_K_M.gguf
- **Offloading**: 45/65 layers on GPU.
- **TurboQuant**: turbo2 (2-bit) KV Cache for 128k context support on 16GB VRAM.

## 5. Model Acquisition
The model was downloaded using the `hf` CLI tool (hf-cli) with the `hf_transfer` accelerator.

```bash
# Install hf-cli if needed
uvx hf --help

# Download the pre-quantized Q4_K_M GGUF
HF_HUB_ENABLE_HF_TRANSFER=1 uvx --with hf_transfer hf download bartowski/Qwen2.5-Coder-32B-Instruct-GGUF \
    --local-dir models \
    --include "*Q4_K_M.gguf" \
    --max-workers 16
```
