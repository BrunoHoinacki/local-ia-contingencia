# local-ia-contingencia

## O problema

Uso Claude Code, Codex e Antigravity no dia a dia para desenvolver. O problema é que
os tokens/créditos de todas as ferramentas acabam em algum momento — geralmente ao
mesmo tempo, no meio de algo — e sem nenhuma delas disponível eu simplesmente fico
travado, sem conseguir continuar o projeto até renovar os limites.

Este repo resolve isso com uma IA de código **local**, rodando na própria máquina via
Ollama + ROCm (aceleração por GPU AMD), como fallback/contingência. Ela roda um
modelo bem menor (qwen2.5-coder:7b) e a qualidade **não chega perto** das ferramentas
pagas — mas é o suficiente para não ficar 100% parado enquanto os créditos não voltam.

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
aider
```

## O que é o aider e como ele se conecta ao Ollama

[Aider](https://aider.chat) é um CLI open source de "pair programming" com IA: você
descreve o que quer no chat e ele edita os arquivos do seu projeto diretamente,
committando no git. É o equivalente em terminal ao Claude Code/Cursor, mas
compatível com vários provedores de LLM (OpenAI, Anthropic, OpenRouter, ou um
modelo local via Ollama — que é o nosso caso aqui).

O Ollama roda **dentro do Docker**, mas expõe uma API HTTP na porta 11434 do
host (`-p 11434:11434` no `docker run`). O aider roda **fora** do container
(instalado no host via `pipx`) e conversa com essa API pela rede — ele não
precisa nem deve rodar dentro do Docker.

Por padrão, se você roda `aider` sem `--model`, ele não sabe qual modelo usar
e tenta te ajudar a escolher, sugerindo criar login no **OpenRouter** (um
marketplace de LLMs hospedados na nuvem) — o que não faz sentido pra quem já
tem um modelo local rodando. O script `02-pos-reboot-ollama.sh` evita isso
criando `~/.aider.conf.yml` com `model: ollama/qwen2.5-coder:7b`, então
`aider` sozinho já usa o modelo local direto, sem esse onboarding.

Se esse prompt do OpenRouter aparecer de novo, o arquivo `~/.aider.conf.yml`
não foi criado (rode `bash 02-pos-reboot-ollama.sh` de novo) — nesse caso,
force o modelo manualmente com `aider --model ollama/qwen2.5-coder:7b`.

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

## Problema conhecido: `pip: command not found`

O Ubuntu 24.04 não vem com `pip` no PATH por padrão e, mesmo instalando
`python3-pip`, o PEP 668 bloqueia `pip install` fora de um virtualenv
(erro `externally-managed-environment`).

**A solução usada aqui:** o script `02-pos-reboot-ollama.sh` instala o aider via
`pipx`, que cria um venv isolado automaticamente para o CLI. Se o comando
`aider` não for encontrado depois do script rodar, abra um novo terminal (ou
rode `source ~/.bashrc`) para o PATH atualizar.

## Verificando se a GPU foi detectada

```bash
rocminfo | grep "Agent 2" -A 5
```

Deve listar sua GPU AMD como um "Agent" de tipo GPU, com nome/modelo correspondente.
