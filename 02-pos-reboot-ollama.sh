#!/bin/bash
set -e

echo "=== [1/3] Verificando ROCm ==="
rocminfo | grep "Agent 2" -A 5

# Detecta o gfx target real da GPU (ex: gfx1032 na RX 6600) e decide se
# precisa de HSA_OVERRIDE_GFX_VERSION. O Ollama/rocBLAS so tem suporte
# oficial a uma lista fechada de alvos (gfx1030, gfx11xx, etc.); GPUs
# RDNA2 "de consumo" fora dessa lista (gfx1031/1032/1034/1035/1036 --
# RX 6700/6600/6500/6400) sao silenciosamente rebaixadas pra CPU sem
# isso, sem nenhum erro visivel -- so rodam bem mais devagar.
GFX_TARGET=$(rocminfo | grep "Agent 2" -A 5 | grep "  Name:" | awk '{print $2}')
HSA_OVERRIDE=""
case "$GFX_TARGET" in
  gfx1030|gfx1100|gfx1101|gfx1102|gfx1150|gfx1151|gfx1200|gfx1201|gfx908|gfx90a|gfx942|gfx950)
    echo "GPU $GFX_TARGET ja e suportada nativamente pelo ROCm, sem override."
    ;;
  gfx103*)
    echo "GPU $GFX_TARGET nao esta na lista oficial do rocBLAS; usando"
    echo "HSA_OVERRIDE_GFX_VERSION=10.3.0 pra mapear pra gfx1030 (mesma familia RDNA2)."
    HSA_OVERRIDE="10.3.0"
    ;;
  *)
    echo "AVISO: GPU $GFX_TARGET desconhecida pro rocBLAS. Se a inferencia"
    echo "cair pra CPU (confira com 'docker exec ollama ollama ps'), pode"
    echo "ser necessario setar HSA_OVERRIDE_GFX_VERSION manualmente."
    ;;
esac

echo ""
echo "=== [2/3] Subindo Ollama com ROCm no Docker ==="
ENV_ARGS=()
if [ -n "$HSA_OVERRIDE" ]; then
  ENV_ARGS=(-e "HSA_OVERRIDE_GFX_VERSION=$HSA_OVERRIDE")
fi

NEEDS_RECREATE=1
if docker ps -a --format '{{.Names}}' | grep -qx ollama; then
  CURRENT_OVERRIDE=$(docker inspect ollama --format '{{range .Config.Env}}{{println .}}{{end}}' | sed -n 's/^HSA_OVERRIDE_GFX_VERSION=//p')
  if [ "$CURRENT_OVERRIDE" = "$HSA_OVERRIDE" ]; then
    NEEDS_RECREATE=0
  fi
fi

if [ "$NEEDS_RECREATE" = 0 ]; then
  echo "Container 'ollama' ja existe com a config de GPU certa, iniciando..."
  docker start ollama
else
  if docker ps -a --format '{{.Names}}' | grep -qx ollama; then
    echo "Container 'ollama' existe mas com config de GPU desatualizada -- recriando..."
    docker rm -f ollama > /dev/null
  fi
  docker run -d \
    --device /dev/kfd \
    --device /dev/dri \
    "${ENV_ARGS[@]}" \
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
# chat-language forca as respostas em pt-BR por padrao.
cat > "$HOME/.aider.conf.yml" <<'YAML'
model: ollama/qwen2.5-coder:7b
show-model-warnings: false
chat-language: pt-BR
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
# chat-ia: script que fala direto com a API do Ollama (sem acesso a
# arquivos, so texto), respondendo sempre em pt-BR e mostrando so o
# tempo de resposta (em vez do bloco inteiro de estatisticas do
# "ollama run --verbose"). ia-cli: agente de codigo (le/edita seus
# arquivos, estilo Claude Code/Cursor) -- alias pro aider.
if ! command -v jq &> /dev/null; then
  sudo apt install -y jq
fi

mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/chat-ia" <<'SCRIPT'
#!/bin/bash
MODEL="qwen2.5-coder:7b"
API="http://127.0.0.1:11434/api/chat"
SYSTEM_PROMPT="Você é um assistente de programação. Responda sempre em português do Brasil (pt-BR), de forma direta e objetiva, a menos que o usuário peça outro idioma."

C_YOU='\033[1;36m'
C_IA='\033[1;32m'
C_DIM='\033[2m'
C_RESET='\033[0m'

messages=$(jq -n --arg c "$SYSTEM_PROMPT" '[{role:"system", content:$c}]')

echo -e "chat-ia — $MODEL (digite /bye para sair)"
while true; do
  printf "\n${C_YOU}você:${C_RESET} "
  if ! IFS= read -r line; then
    echo ""
    break
  fi
  [ -z "$line" ] && continue
  [ "$line" = "/bye" ] && break

  messages=$(jq --arg c "$line" '. + [{role:"user", content:$c}]' <<< "$messages")

  frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  (
    i=0
    while true; do
      idx=$(( i % ${#frames} ))
      printf "\r${C_DIM}%s pensando...${C_RESET}" "${frames:$idx:1}"
      i=$((i + 1))
      sleep 0.1
    done
  ) &
  spinner_pid=$!

  start=$(date +%s.%N)
  body=$(jq -n --argjson msgs "$messages" --arg model "$MODEL" '{model:$model, messages:$msgs, stream:false}')
  response=$(curl -s "$API" -d "$body")
  end=$(date +%s.%N)

  kill "$spinner_pid" 2>/dev/null
  wait "$spinner_pid" 2>/dev/null
  printf "\r\033[K"

  content=$(jq -r '.message.content // empty' <<< "$response")
  if [ -z "$content" ]; then
    echo "[erro] $(jq -r '.error // "sem resposta do Ollama"' <<< "$response")"
    continue
  fi

  echo -e "${C_IA}ia:${C_RESET} $content"
  elapsed=$(awk -v s="$start" -v e="$end" 'BEGIN{printf "%.1f", e-s}')
  echo -e "${C_DIM}⏱  ${elapsed}s${C_RESET}"

  messages=$(jq --arg c "$content" '. + [{role:"assistant", content:$c}]' <<< "$messages")
done
SCRIPT
chmod +x "$HOME/.local/bin/chat-ia"

# versoes antigas do script deixavam "chat-ia" como alias no bashrc;
# remove pra nao sombrear o script novo em ~/.local/bin.
sed -i '/^alias chat-ia=/d' "$HOME/.bashrc" 2>/dev/null || true

# Ao abrir, o ia-cli manda um /ask automatico pedindo pro modelo resumir
# o repo-map e perguntar o que fazer -- parecido com a saudacao inicial
# do Claude Code. Isso usa o repo-map (so nomes/estrutura de arquivo),
# entao ele nao "le" o conteudo dos arquivos ate voce dar /add ou --file.
cat > "$HOME/.aider-startup.aider" <<'AIDERCMDS'
/ask Descreva em poucas linhas (repo-map) a estrutura deste projeto e pergunte objetivamente o que eu gostaria de fazer agora.
AIDERCMDS

sed -i '/^alias ia-cli=/d' "$HOME/.bashrc" 2>/dev/null || true
echo "alias ia-cli=\"aider --load \$HOME/.aider-startup.aider\"" >> "$HOME/.bashrc"

echo ""
echo "======================================"
echo "Tudo pronto! Abra um novo terminal (ou rode 'source ~/.bashrc')"
echo "para os atalhos abaixo ficarem disponiveis."
echo ""
echo "Para usar:"
echo "  chat-ia  -> chat cru com o modelo, responde em pt-BR e mostra o tempo"
echo "  ia-cli   -> agente de codigo que le/edita seu projeto (via aider)"
echo "             ao abrir, ja resume o projeto e pergunta o que fazer"
echo "             (pode demorar alguns segundos nesse modelo). Pra editar"
echo "             um arquivo, use /add <arquivo> antes de pedir a mudanca."
echo "             Pra sair: /exit"
echo "======================================"
