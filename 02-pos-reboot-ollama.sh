#!/bin/bash
set -e

echo "=== [1/3] Verificando ROCm ==="
rocminfo | grep "Agent 2" -A 5

echo ""
echo "=== [2/3] Subindo Ollama com ROCm no Docker ==="
docker run -d \
  --device /dev/kfd \
  --device /dev/dri \
  -v ollama:/root/.ollama \
  -p 11434:11434 \
  --name ollama \
  ollama/ollama:rocm

echo "Aguardando Ollama iniciar..."
sleep 5

echo ""
echo "=== [3/3] Baixando modelo qwen2.5-coder:7b (~4GB) ==="
docker exec -it ollama ollama pull qwen2.5-coder:7b

echo ""
echo "=== Instalando aider (CLI de codigo) ==="
pip install aider-chat

echo ""
echo "======================================"
echo "Tudo pronto! Para usar:"
echo "  Chat:  docker exec -it ollama ollama run qwen2.5-coder:7b"
echo "  Aider: aider --model ollama/qwen2.5-coder:7b"
echo "======================================"
