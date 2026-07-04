#!/bin/bash
set -e

echo "=== [1/3] Verificando ROCm ==="
rocminfo | grep "Agent 2" -A 5

echo ""
echo "=== [2/3] Subindo Ollama com ROCm no Docker ==="
if docker ps -a --format '{{.Names}}' | grep -qx ollama; then
  echo "Container 'ollama' ja existe, iniciando..."
  docker start ollama
else
  docker run -d \
    --device /dev/kfd \
    --device /dev/dri \
    -v ollama:/root/.ollama \
    -p 11434:11434 \
    --name ollama \
    ollama/ollama:rocm
fi

echo "Aguardando Ollama iniciar..."
sleep 5

echo ""
echo "=== [3/3] Baixando modelo qwen2.5-coder:7b (~4GB) ==="
docker exec -it ollama ollama pull qwen2.5-coder:7b

echo ""
echo "=== Instalando aider (CLI de codigo) ==="
# NOTA: Ubuntu 24.04 nao tem "pip" no PATH por padrao e, mesmo com
# python3-pip instalado, o PEP 668 bloqueia "pip install" fora de um venv
# ("externally-managed-environment"). pipx resolve isso instalando o aider
# em um venv isolado automaticamente.
if ! command -v pipx &> /dev/null; then
  sudo apt install -y pipx
fi
pipx install aider-chat
pipx ensurepath

echo ""
echo "=== Configurando o aider para usar o Ollama local por padrao ==="
# Sem isso, "aider" (sem --model) nao sabe que modelo usar e oferece
# configurar um provedor na nuvem (OpenRouter) em vez do Ollama local.
cat > "$HOME/.aider.conf.yml" <<'YAML'
model: ollama/qwen2.5-coder:7b
YAML

echo ""
echo "======================================"
echo "Tudo pronto! Se o comando 'aider' nao for encontrado, abra um"
echo "novo terminal (ou rode 'source ~/.bashrc') para o PATH atualizar."
echo ""
echo "Para usar:"
echo "  Chat:  docker exec -it ollama ollama run qwen2.5-coder:7b"
echo "  Aider: aider   (ja usa o modelo local por padrao)"
echo "======================================"
