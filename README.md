# local-ia-contingencia

Setup de uma IA de código local (Ollama + qwen2.5-coder, acelerado por GPU AMD via ROCm)
para servir como contingência quando serviços de IA em nuvem estiverem fora do ar.

Testado em:
- Ubuntu 24.04 LTS (noble)
- GPU AMD Radeon RX 6600 (Navi 23, RDNA 2)

## Requisitos

- GPU AMD RDNA 2 (RX 6xxx) ou RDNA 3 (RX 7xxx)
- Docker instalado
- Usuário com acesso a `sudo`

## Uso

```bash
# 1. Instala os pacotes ROCm e adiciona seu usuário aos grupos necessários
bash 01-instalar-rocm.sh

# 2. Reinicie o PC (necessário para os grupos render/video e módulos de kernel)

# 3. Sobe o Ollama no Docker com aceleração ROCm, baixa o modelo e instala o aider
bash 02-pos-reboot-ollama.sh
```

Depois de pronto:

```bash
# Chat interativo
docker exec -it ollama ollama run qwen2.5-coder:7b

# Usando como CLI de código (estilo Claude Code/Cursor)
aider --model ollama/qwen2.5-coder:7b
```

## Problema conhecido: `rocm-opencl-icd`

O guia mais comum para instalar ROCm no Ubuntu manda instalar um pacote chamado
`rocm-opencl-icd`. Em julho de 2026, esse pacote **não existe** nos repositórios
oficiais do Ubuntu 24.04 (`apt-cache policy rocm-opencl-icd` não retorna candidato,
mesmo com `universe`/`multiverse` habilitados e `apt update` em dia).

Isso derruba silenciosamente qualquer script de instalação baseado num único
`apt install pacote1 pacote2 ... rocm-opencl-icd ...`, porque o apt recusa instalar
*qualquer* pacote da lista se um dos nomes não existir — e sem checagem de erro no
script, a mensagem de "sucesso" aparece mesmo assim.

**A solução usada aqui:** remover `rocm-opencl-icd` da lista. O Ollama usa o runtime
**HIP** do ROCm para aceleração de GPU, não o OpenCL, então o pacote não faz falta
para este caso de uso. Os demais 17 pacotes (`rocminfo`, `rocm-smi`, `hipcc`,
`librocblas0`, etc.) existem normalmente nos repositórios padrão do Ubuntu 24.04.

## Verificando se a GPU foi detectada

```bash
rocminfo | grep "Agent 2" -A 5
```

Deve listar sua GPU AMD como um "Agent" de tipo GPU, com nome/modelo correspondente.
