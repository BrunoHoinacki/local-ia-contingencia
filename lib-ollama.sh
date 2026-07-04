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
