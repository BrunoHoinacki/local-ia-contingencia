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
# -t so funciona com um terminal de verdade; sem isso, "docker exec -it"
# quebra quando o script roda de forma nao-interativa (cron, CI, etc).
if [ -t 0 ]; then
  docker exec -it ollama ollama pull qwen2.5-coder:7b
else
  docker exec -i ollama ollama pull qwen2.5-coder:7b
fi

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
show-model-warnings: false
YAML

# Sem OLLAMA_API_BASE, o aider avisa (com link pra doc) que a variavel
# nao esta definida antes de cada resposta. O Ollama do Docker ja expoe
# a API em 127.0.0.1:11434, entao so precisamos declarar isso uma vez.
if ! grep -q "^export OLLAMA_API_BASE=" "$HOME/.bashrc" 2>/dev/null; then
  echo 'export OLLAMA_API_BASE=http://127.0.0.1:11434' >> "$HOME/.bashrc"
fi
export OLLAMA_API_BASE=http://127.0.0.1:11434

echo ""
echo "=== Criando atalhos chat-ia e ia-cli ==="
# chat-ia: conversa crua com o modelo (sem acesso a arquivos, so texto).
# ia-cli:  agente de codigo (le/edita seus arquivos, estilo Claude Code/Cursor).
if ! grep -q "^alias chat-ia=" "$HOME/.bashrc" 2>/dev/null; then
  echo "alias chat-ia='docker exec -it ollama ollama run qwen2.5-coder:7b --verbose'" >> "$HOME/.bashrc"
fi
if ! grep -q "^alias ia-cli=" "$HOME/.bashrc" 2>/dev/null; then
  echo "alias ia-cli='aider'" >> "$HOME/.bashrc"
fi

echo ""
echo "======================================"
echo "Tudo pronto! Abra um novo terminal (ou rode 'source ~/.bashrc')"
echo "para os atalhos abaixo ficarem disponiveis."
echo ""
echo "Para usar:"
echo "  chat-ia  -> chat cru com o modelo (mostra tempo/tokens por segundo)"
echo "  ia-cli   -> agente de codigo que le/edita seu projeto (via aider)"
echo "======================================"
