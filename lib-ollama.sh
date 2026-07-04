#!/bin/bash
# Biblioteca compartilhada entre 02-pos-reboot-ollama.sh e tools.sh:
# sobe/recria o container do Ollama com a config de GPU
# (HSA_OVERRIDE_GFX_VERSION) e de limites de recursos (CPU/RAM) certas.
# So define funcoes -- precisa ser sourceado, nao executado direto.

RESOURCES_FILE="$HOME/.ia-local-resources"

ler_recursos() {
  IA_CPUS=""
  IA_MEM=""
  if [ -f "$RESOURCES_FILE" ]; then
    # shellcheck disable=SC1090
    source "$RESOURCES_FILE"
  fi
}

detectar_gfx_override() {
  # Detecta o gfx target real da GPU (ex: gfx1032 na RX 6600) e decide
  # se precisa de HSA_OVERRIDE_GFX_VERSION. O Ollama/rocBLAS so tem
  # suporte oficial a uma lista fechada de alvos (gfx1030, gfx11xx,
  # etc.); GPUs RDNA2 "de consumo" fora dessa lista (gfx1031/1032/
  # 1034/1035/1036 -- RX 6700/6600/6500/6400) sao silenciosamente
  # rebaixadas pra CPU sem isso, sem nenhum erro visivel.
  local gfx_target
  gfx_target=$(rocminfo | grep "Agent 2" -A 5 | grep "  Name:" | awk '{print $2}')
  HSA_OVERRIDE=""
  case "$gfx_target" in
    gfx1030|gfx1100|gfx1101|gfx1102|gfx1150|gfx1151|gfx1200|gfx1201|gfx908|gfx90a|gfx942|gfx950)
      echo "GPU $gfx_target ja e suportada nativamente pelo ROCm, sem override."
      ;;
    gfx103*)
      echo "GPU $gfx_target nao esta na lista oficial do rocBLAS; usando"
      echo "HSA_OVERRIDE_GFX_VERSION=10.3.0 pra mapear pra gfx1030 (mesma familia RDNA2)."
      HSA_OVERRIDE="10.3.0"
      ;;
    *)
      echo "AVISO: GPU $gfx_target desconhecida pro rocBLAS. Se a inferencia"
      echo "cair pra CPU (confira com 'docker exec ollama ollama ps'), pode"
      echo "ser necessario setar HSA_OVERRIDE_GFX_VERSION manualmente."
      ;;
  esac
}

subir_container_ollama() {
  detectar_gfx_override
  ler_recursos

  ENV_ARGS=()
  if [ -n "$HSA_OVERRIDE" ]; then
    ENV_ARGS+=(-e "HSA_OVERRIDE_GFX_VERSION=$HSA_OVERRIDE")
  fi

  RES_ARGS=()
  if [ -n "$IA_CPUS" ]; then
    RES_ARGS+=(--cpus "$IA_CPUS")
  fi
  if [ -n "$IA_MEM" ]; then
    RES_ARGS+=(--memory "$IA_MEM")
  fi

  DESIRED_NANO_CPUS=0
  if [ -n "$IA_CPUS" ]; then
    DESIRED_NANO_CPUS=$(awk -v c="$IA_CPUS" 'BEGIN{printf "%d", c*1000000000}')
  fi
  DESIRED_MEM_BYTES=0
  if [ -n "$IA_MEM" ]; then
    DESIRED_MEM_BYTES=$(numfmt --from=iec "$(echo "$IA_MEM" | tr '[:lower:]' '[:upper:]')" 2>/dev/null || echo 0)
  fi

  NEEDS_RECREATE=1
  if docker ps -a --format '{{.Names}}' | grep -qx ollama; then
    CURRENT_OVERRIDE=$(docker inspect ollama --format '{{range .Config.Env}}{{println .}}{{end}}' | sed -n 's/^HSA_OVERRIDE_GFX_VERSION=//p')
    CURRENT_CPUS=$(docker inspect ollama --format '{{.HostConfig.NanoCpus}}')
    CURRENT_MEM=$(docker inspect ollama --format '{{.HostConfig.Memory}}')
    if [ "$CURRENT_OVERRIDE" = "$HSA_OVERRIDE" ] && [ "$CURRENT_CPUS" = "$DESIRED_NANO_CPUS" ] && [ "$CURRENT_MEM" = "$DESIRED_MEM_BYTES" ]; then
      NEEDS_RECREATE=0
    fi
  fi

  if [ "$NEEDS_RECREATE" = 0 ]; then
    echo "Container 'ollama' ja existe com a config certa, iniciando..."
    docker start ollama
  else
    if docker ps -a --format '{{.Names}}' | grep -qx ollama; then
      echo "Container 'ollama' existe mas com config desatualizada -- recriando..."
      docker rm -f ollama > /dev/null
    fi
    docker run -d \
      --device /dev/kfd \
      --device /dev/dri \
      "${ENV_ARGS[@]}" \
      "${RES_ARGS[@]}" \
      -v ollama:/root/.ollama \
      -p 11434:11434 \
      --name ollama \
      ollama/ollama:rocm
  fi
}

# Lista curada ate jan/2026 de modelos de codigo que rodam bem via Ollama.
# Ja saiu (ou vai sair) coisa mais nova -- antes de escolher, vale conferir
# https://ollama.com/library?q=coder. A opcao "outro" do menu aceita
# qualquer tag do Ollama, entao a lista nunca trava ninguem num modelo velho.
# Formato de cada entrada: tag|download aproximado|VRAM recomendada|descricao
MODELOS_CODIGO=(
  "qwen2.5-coder:7b|~4GB|6-8GB|leve e rapido, bom padrao pra GPUs menores"
  "deepseek-coder-v2:16b|~9GB|10-12GB|MoE (16B total, poucos parametros ativos por token): rapido e competente"
  "qwen2.5-coder:14b|~9GB|12-16GB|mais coerente que o 7b em tarefas maiores"
  "codestral:22b|~13GB|16-24GB|modelo de codigo da Mistral, bom equilibrio"
  "qwen2.5-coder:32b|~19GB|24GB+|o mais forte da familia Qwen coder pra rodar local"
)

# Pergunta ao usuario qual modelo instalar/trocar. Define MODELO_ESCOLHIDO.
escolher_modelo() {
  echo ""
  echo "=== Qual modelo de codigo usar? ==="
  echo "Escolha pela VRAM da sua GPU (modelo maior = melhor qualidade, porem mais"
  echo "lento e com mais uso de memoria). Lista curada ate jan/2026 -- de olho em"
  echo "https://ollama.com/library?q=coder pra ver se saiu algo melhor nesse meio tempo."
  echo ""
  local i=1
  for entry in "${MODELOS_CODIGO[@]}"; do
    IFS='|' read -r tag download vram desc <<< "$entry"
    printf "  %d) %-22s (%s download, %s VRAM) -- %s\n" "$i" "$tag" "$download" "$vram" "$desc"
    i=$((i + 1))
  done
  echo "  $i) Outro (digitar o nome do modelo manualmente)"
  echo ""
  local padrao_tag
  padrao_tag="${MODELOS_CODIGO[0]%%|*}"
  read -rp "Opcao [ENTER = 1, $padrao_tag]: " escolha
  escolha="${escolha:-1}"

  if [ "$escolha" = "$i" ]; then
    read -rp "Nome do modelo no Ollama (ex: llama3.1:8b): " MODELO_ESCOLHIDO
  elif [[ "$escolha" =~ ^[0-9]+$ ]] && [ "$escolha" -ge 1 ] && [ "$escolha" -lt "$i" ]; then
    IFS='|' read -r MODELO_ESCOLHIDO _ _ _ <<< "${MODELOS_CODIGO[$((escolha - 1))]}"
  else
    echo "Opcao invalida, usando o padrao ($padrao_tag)."
    MODELO_ESCOLHIDO="$padrao_tag"
  fi
  echo "Modelo escolhido: $MODELO_ESCOLHIDO"
}

# Baixa o modelo escolhido no container do Ollama.
baixar_modelo() {
  local modelo="$1"
  echo ""
  echo "=== Baixando modelo $modelo ==="
  # -t so funciona com um terminal de verdade; sem isso, "docker exec -it"
  # quebra quando o script roda de forma nao-interativa (cron, CI, etc).
  if [ -t 0 ]; then
    docker exec -it ollama ollama pull "$modelo"
  else
    docker exec -i ollama ollama pull "$modelo"
  fi
}

CONVENTIONS_FILE="$HOME/.aider-conventions.md"

# Arquivo somente-leitura sempre carregado no ia-cli (via "read:" no
# aider.conf.yml) com instrucoes de comportamento -- tenta corrigir o
# habito do aider de sair editando/commitando direto sem perguntar.
# E "melhor esforco": modelo pequeno local nao segue instrucao tao bem
# quanto um modelo grande, mas ajuda bastante.
criar_conventions() {
  cat > "$CONVENTIONS_FILE" <<'CONV'
# Como este agente deve se comportar

- Antes de editar qualquer arquivo, explique em poucas linhas o que pretende
  mudar e pergunte se pode aplicar -- a menos que o pedido do usuario ja seja
  uma instrucao direta e especifica (ex.: "corrige a funcao X pra fazer Y",
  "adiciona um campo Z na tabela W").
- Se o pedido for vago ou aberto (ex.: "qual o proximo passo", "o que voce
  acha", "leia o roadmap e me diga"), responda com analise e pergunta, e NAO
  edite nenhum arquivo ainda. Espere o usuario confirmar o que ele quer.
- Nunca edite ou sobrescreva um arquivo que nao foi mencionado ou pedido
  explicitamente na conversa, mesmo que pareca relacionado.
- Prefira mudancas minimas e cirurgicas no arquivo certo. Nunca reescreva um
  arquivo inteiro quando a intencao e uma alteracao pontual.
- Depois de aplicar uma mudanca, diga em 1-2 linhas o que foi alterado e em
  qual arquivo.
CONV
}

# Aponta aider (~/.aider.conf.yml) e chat-ia pro modelo escolhido. Funciona
# tanto na instalacao inicial quanto pra trocar de modelo depois -- por isso
# fica na lib compartilhada em vez de duplicado em cada script.
atualizar_config_modelo() {
  local modelo="$1"
  if [ ! -f "$CONVENTIONS_FILE" ]; then
    criar_conventions
  fi
  cat > "$HOME/.aider.conf.yml" <<YAML
model: ollama/$modelo
show-model-warnings: false
chat-language: pt-BR
auto-commits: false
read:
  - $CONVENTIONS_FILE
YAML

  if [ -f "$HOME/.local/bin/chat-ia" ]; then
    sed -i "s|^MODEL=.*|MODEL=\"$modelo\"|" "$HOME/.local/bin/chat-ia"
  fi
  echo "Config atualizada: aider e chat-ia agora usam $modelo."
}
