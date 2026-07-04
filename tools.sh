#!/bin/bash
# Menu interativo que centraliza todas as rotinas do setup: instalar o
# ROCm, subir/configurar o Ollama + aider depois do reboot, ver status
# e parar/subir a IA quando quiser. Reentrante -- pode fechar e abrir
# de novo a qualquer momento (inclusive logo depois do reboot).
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

status() {
  echo "=== GPU (ROCm) ==="
  if command -v rocminfo &> /dev/null; then
    rocminfo | grep "Agent 2" -A 5
  else
    echo "rocminfo nao encontrado -- rode a opcao 1 (Instalar ROCm) primeiro."
  fi

  echo ""
  echo "=== Container Ollama ==="
  if docker ps -a --format '{{.Names}}\t{{.Status}}' 2>/dev/null | grep -q "^ollama"; then
    docker ps -a --format '{{.Names}}\t{{.Status}}' | grep "^ollama"
  else
    echo "Container 'ollama' ainda nao existe -- rode a opcao 2."
  fi

  echo ""
  echo "=== Modelo carregado (CPU ou GPU?) ==="
  if docker ps --format '{{.Names}}' 2>/dev/null | grep -qx ollama; then
    docker exec ollama ollama ps
  else
    echo "Container nao esta rodando."
  fi

  echo ""
  echo "=== aider / chat-ia / ia-cli ==="
  if [ -f "$HOME/.aider.conf.yml" ]; then
    echo "~/.aider.conf.yml:"
    cat "$HOME/.aider.conf.yml"
  else
    echo "aider ainda nao configurado -- rode a opcao 2."
  fi
  if [ -x "$HOME/.local/bin/chat-ia" ]; then
    echo "chat-ia: instalado em ~/.local/bin/chat-ia"
  else
    echo "chat-ia: ainda nao instalado -- rode a opcao 2."
  fi
}

parar_ia() {
  if docker ps --format '{{.Names}}' 2>/dev/null | grep -qx ollama; then
    docker stop ollama
    echo "Ollama parado. GPU liberada. Use a opcao 5 pra subir de novo."
  else
    echo "Ollama ja esta parado (ou nunca foi criado)."
  fi
}

subir_ia() {
  if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qx ollama; then
    docker start ollama
    echo "Ollama iniciado."
  else
    echo "Container ainda nao existe -- rode a opcao 2 (Configurar Ollama) primeiro."
  fi
}

pausa() {
  echo ""
  read -rp "Pressione ENTER pra voltar ao menu... " _
}

menu() {
  while true; do
    clear 2>/dev/null || true
    echo "======================================"
    echo " IA Local de Contingencia -- tools.sh"
    echo "======================================"
    echo "1) Instalar ROCm            (rodar ANTES do 1o reboot)"
    echo "2) Configurar Ollama + aider (rodar DEPOIS do reboot)"
    echo "3) Status (GPU, container, modelo, aider)"
    echo "4) Parar a IA  (derruba o container, libera a GPU)"
    echo "5) Subir a IA  (inicia o container parado)"
    echo "0) Sair"
    echo "======================================"
    read -rp "Escolha uma opcao: " opcao
    echo ""
    case "$opcao" in
      1) bash "$SCRIPT_DIR/01-instalar-rocm.sh"; pausa ;;
      2) bash "$SCRIPT_DIR/02-pos-reboot-ollama.sh"; pausa ;;
      3) status; pausa ;;
      4) parar_ia; pausa ;;
      5) subir_ia; pausa ;;
      0) exit 0 ;;
      *) echo "Opcao invalida."; pausa ;;
    esac
  done
}

menu
