#!/bin/bash
set -e

echo "=== [1/2] Instalando pacotes ROCm ==="
# NOTA: o pacote "rocm-opencl-icd" nao existe nos repositorios do Ubuntu 24.04
# (testado em 2026-07, com apt update em dia). O Ollama usa o runtime HIP do
# ROCm, nao o OpenCL, entao ele nao faz falta para este setup.
sudo apt install -y \
  libamd-comgr2 libhsa-runtime64-1 librccl1 librocalution0 librocblas0 \
  librocfft0 librocm-smi64-1 librocsolver0 librocsparse0 rocm-device-libs-17 \
  rocm-smi rocminfo hipcc libhiprand1 libhiprtc-builtins5 radeontop \
  ocl-icd-libopencl1 clinfo

echo "=== [2/2] Adicionando usuario aos grupos render e video ==="
sudo usermod -aG render,video "$USER"

echo ""
echo "=== Pronto! ==="
echo "Reinicie o PC agora e depois rode: bash 02-pos-reboot-ollama.sh"
