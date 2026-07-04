#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-ollama.sh
source "$SCRIPT_DIR/lib-ollama.sh"

echo "=== [1/3] Verificando ROCm ==="
rocminfo | grep "Agent 2" -A 5

echo ""
echo "=== [2/3] Subindo Ollama com ROCm no Docker ==="
subir_container_ollama

echo "Aguardando Ollama iniciar..."
sleep 5

echo ""
echo "=== [3/3] Escolhendo e baixando o modelo de codigo ==="
escolher_modelo
baixar_modelo "$MODELO_ESCOLHIDO"

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
# Recria sempre do zero pra pegar atualizacoes de instrucao deste script.
criar_conventions
# A escrita de fato do ~/.aider.conf.yml (com o modelo escolhido acima) fica
# pra depois de criar o chat-ia, via atualizar_config_modelo -- ela mexe nos
# dois arquivos de uma vez (funcao compartilhada com o "trocar modelo" do
# tools.sh).

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
MODEL="__MODELO_PLACEHOLDER__"
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

# Agora que aider e chat-ia ja existem, aponta os dois pro modelo escolhido
# no passo 3 (substitui o placeholder do heredoc acima e escreve o
# ~/.aider.conf.yml final).
atualizar_config_modelo "$MODELO_ESCOLHIDO"

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
