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

Tudo passa por um menu interativo, o `tools.sh` — pode fechar e abrir de novo
a qualquer momento (inclusive logo depois do reboot):

```bash
bash tools.sh
```

```
======================================
 IA Local de Contingencia -- tools.sh
======================================
1) Instalar ROCm            (rodar ANTES do 1o reboot)
2) Configurar Ollama + aider (rodar DEPOIS do reboot)
3) Status (GPU, container, modelo, aider)
4) Parar a IA  (derruba o container, libera a GPU)
5) Subir a IA  (inicia o container parado)
6) Ajustar recursos da IA (CPU/RAM)
0) Sair
======================================
```

Fluxo típico: abra o `tools.sh`, escolha **1** (instala os pacotes ROCm e
detecta sua GPU automaticamente — não precisa configurar nada manualmente,
mesmo em outra máquina), reinicie o PC, abra o `tools.sh` de novo e escolha
**2** (sobe o Ollama, baixa o modelo e configura `aider`/`chat-ia`/`ia-cli`).
Depois disso, use a opção **3** sempre que quiser conferir se está tudo
rodando (e se a GPU está mesmo sendo usada), **4**/**5** pra parar/subir a
IA quando quiser liberar ou usar a GPU de novo, e **6** pra limitar quanta
CPU/RAM o container pode usar (pergunta os valores, mostra o antes/depois e
só recria o container depois que você confirmar).

As opções 1 e 2 são as mesmas rotinas dos scripts `01-instalar-rocm.sh` e
`02-pos-reboot-ollama.sh` — ainda dá pra rodar cada um separadamente se
preferir, o `tools.sh` só empacota tudo num lugar só. A lógica de subir o
container (detecção de GPU + limites de recursos) fica em `lib-ollama.sh`,
compartilhada entre `tools.sh` e `02-pos-reboot-ollama.sh`.

Depois de configurado (opção 2), você tem dois atalhos disponíveis em
qualquer terminal novo (ou rode `source ~/.bashrc`):

```bash
# Chat cru com o modelo, só texto (sem acesso aos seus arquivos)
chat-ia

# Agente de código que lê e edita seu projeto (estilo Claude Code/Cursor)
ia-cli
```

## Qual a diferença entre `chat-ia` e `ia-cli`?

Os dois conversam com o **mesmo modelo** (`qwen2.5-coder:7b` servido pelo
Ollama), mas são camadas bem diferentes:

| | `chat-ia` | `ia-cli` |
|---|---|---|
| O que é | Script próprio que fala com a API do Ollama | Agente de código completo — na verdade é um alias pro [aider](https://aider.chat) |
| Onde roda | No seu host (`~/.local/bin/chat-ia`), conversa com o Ollama pela API HTTP na porta 11434 | No seu host também, mesma API |
| Acesso aos arquivos | Nenhum — só texto puro, ida e volta | Lê seu repositório e decide quais arquivos importam |
| Aplica mudança no código | Não — você copia/cola manualmente o que ele responder | Sim — escreve o diff direto no arquivo |
| Integração com git | Nenhuma | Sim — enxerga o repo e pode até commitar as mudanças |
| Pra que serve | Perguntas rápidas, tirar dúvida, pedir um trecho de exemplo | Trabalhar de fato num projeto: "adiciona uma função X", "corrige esse bug" |

Ou seja: `chat-ia` é só o "cérebro" falando texto. `ia-cli` é esse mesmo
cérebro conectado a ferramentas que leem e escrevem seus arquivos. No dia a
dia de código, o que você vai usar é o `ia-cli`.

### `chat-ia`: idioma, cores e tempo de resposta

`chat-ia` não é um alias — é um script em `~/.local/bin/chat-ia` (criado pelo
`02-pos-reboot-ollama.sh`) que fala direto com a API do Ollama via `curl` +
`jq`. Isso dá controle total sobre a experiência:

- Responde sempre em **pt-BR** por padrão (system prompt fixo).
- Mostra um spinner (`⠋ pensando...`) enquanto espera a resposta, já que o
  modelo pode demorar vários segundos nessa GPU.
- Diferencia visualmente **você** (ciano) da **ia** (verde) e mostra só o
  tempo total da resposta (`⏱ 9.9s`) em vez do bloco inteiro de estatísticas
  do `ollama run --verbose`.
- Mantém o histórico da conversa durante a sessão (mas sem acesso a arquivos
  — é só texto). Pra sair, digite `/bye`.

O `ia-cli` (aider) **não** expõe tempo de resposta por padrão — não existe
flag pra isso. Use o `chat-ia` como referência de velocidade; o `ia-cli`
tende a ser mais lento por request porque manda mais contexto (mapa do
repositório, arquivos abertos, etc.) a cada pergunta.

### Sobre o `ia-cli` (aider) por baixo dos panos

Por padrão, se você rodasse `aider` puro sem nenhum modelo configurado, ele
não saberia qual modelo usar e tentaria te ajudar a escolher, sugerindo
criar login no **OpenRouter** (um marketplace de LLMs hospedados na nuvem) —
o que não faz sentido pra quem já tem um modelo local rodando. O script
`02-pos-reboot-ollama.sh` evita isso criando `~/.aider.conf.yml` com
`model: ollama/qwen2.5-coder:7b` e `chat-language: pt-BR`, então o alias
`ia-cli` já usa o modelo local direto (sem onboarding) e responde em
português por padrão.

Se esse prompt do OpenRouter aparecer de novo, o arquivo `~/.aider.conf.yml`
não foi criado (rode `bash 02-pos-reboot-ollama.sh` de novo) — nesse caso,
force o modelo manualmente com `aider --model ollama/qwen2.5-coder:7b`.

Ao abrir, `ia-cli` já manda um `/ask` automático pedindo pro modelo resumir
a estrutura do projeto (repo-map) e perguntar o que você quer fazer — parecido
com a saudação inicial do Claude Code. Isso pode levar alguns segundos nesse
modelo. Pra sair da sessão, o comando é `/exit` (não `/bye` — isso é coisa
do Ollama, não do aider).

Logo depois dessa saudação, pode aparecer a mensagem `Command '/ask ...' is
only supported in interactive mode, skipping.` — é **cosmética e inofensiva**:
o `/ask` sempre tenta trocar de "modo" de chat depois de responder, e isso
não é permitido dentro de um `--load`, mas a resposta em si (o resumo e a
pergunta) já apareceu completa antes dessa mensagem. O chat continua normal
depois.

**Importante:** o repo-map só tem os *nomes* dos arquivos, não o conteúdo. Pra
aider realmente ler e editar um arquivo, adicione-o à conversa primeiro com
`/add caminho/do/arquivo.py` (ou abra com `aider --file arquivo.py`). Sem
isso, o modelo pequeno costuma responder "não tenho acesso aos seus
arquivos" — o que é impreciso: ele tem acesso, só não sabe pedir pra
adicionar o arquivo como um modelo maior (Claude, GPT) faria automaticamente.

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

## Problema conhecido: inferência caindo pra CPU sem avisar (RX 6600/6700/6500...)

Em GPUs RDNA2 "de consumo" (RX 6600, 6650, 6700, 6500, 6400 — alvo `gfx1031`,
`gfx1032`, `gfx1034`, `gfx1035`, `gfx1036`), o rocBLAS do Ollama **não** tem
esses alvos na lista de suportados oficialmente. Sem nenhum erro visível, o
Ollama simplesmente roda o modelo inteiro na CPU (`ollama ps` mostra
`100% CPU`) — na prática, isso deixava o `qwen2.5-coder:7b` girando a ~7
tokens/s numa RX 6600, quando a mesma GPU entrega ~35+ tokens/s (5x mais
rápido) usando o ROCm de verdade.

Dá pra confirmar se está acontecendo com você:

```bash
docker exec ollama ollama ps
# PROCESSOR deveria mostrar algo como "100% GPU", nao "100% CPU"
```

**A solução usada aqui:** `02-pos-reboot-ollama.sh` detecta o alvo real da
sua GPU via `rocminfo` e, se ele não estiver na lista suportada mas for da
família RDNA2 (`gfx103*`), sobe o container com
`-e HSA_OVERRIDE_GFX_VERSION=10.3.0` — isso mapeia a GPU pra `gfx1030`
(alvo oficialmente suportado, mesma arquitetura), destravando a aceleração
real. Em GPUs já suportadas nativamente (RX 6800/6900 = `gfx1030`, RDNA3
inteira = `gfx11xx`) esse override **não** é aplicado, porque forçá-lo
nessas placas seria incorreto. Se rodar numa GPU fora dessas listas, o
script avisa e você pode setar `HSA_OVERRIDE_GFX_VERSION` manualmente.

## Verificando se a GPU foi detectada

```bash
rocminfo | grep "Agent 2" -A 5
```

Deve listar sua GPU AMD como um "Agent" de tipo GPU, com nome/modelo correspondente.
