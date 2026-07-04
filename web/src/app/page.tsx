import { CopyCommand } from "@/components/CopyCommand";
import { Mascot } from "@/components/Mascot";
import { PoweredByForcoder } from "@/components/PoweredByForcoder";
import { Reveal } from "@/components/Reveal";

const TOOLS_SEM_CREDITO = [
  { nome: "Claude Code", motivo: "tokens do plano acabaram" },
  { nome: "Codex", motivo: "limite de uso batido" },
  { nome: "Antigravity", motivo: "créditos zerados" },
];

const STACK = [
  { nome: "Ollama", desc: "serve o modelo localmente" },
  { nome: "ROCm", desc: "aceleração por GPU AMD" },
  { nome: "qwen2.5-coder:7b", desc: "modelo de código, ~4GB" },
  { nome: "aider", desc: "CLI de código no terminal" },
];

const PASSOS = [
  {
    numero: "1",
    titulo: "Instala o ROCm",
    desc: "Um script cuida dos pacotes certos (inclusive um bug de pacote inexistente no Ubuntu 24.04 que a gente já contornou pra você).",
    comando: "bash 01-instalar-rocm.sh",
  },
  {
    numero: "2",
    titulo: "Reinicia o PC",
    desc: "Necessário pra carregar os módulos de kernel do ROCm e liberar os grupos render/video pro seu usuário.",
    comando: "reboot",
  },
  {
    numero: "3",
    titulo: "Sobe o Ollama e já usa",
    desc: "Sobe o Ollama com GPU no Docker, baixa o modelo e instala o aider — pronto pra codar.",
    comando: "bash 02-pos-reboot-ollama.sh",
  },
];

export default function Home() {
  return (
    <main className="relative overflow-hidden">
      {/* blobs decorativos de fundo */}
      <div
        aria-hidden
        className="pointer-events-none absolute -left-24 -top-24 h-96 w-96 animate-blob bg-primary/15 blur-3xl"
      />
      <div
        aria-hidden
        className="pointer-events-none absolute -right-20 top-64 h-80 w-80 animate-blob bg-accent/20 blur-3xl"
      />
      <div
        aria-hidden
        className="pointer-events-none absolute left-1/3 top-[120vh] h-72 w-72 animate-blob bg-mint/15 blur-3xl"
      />

      {/* HERO */}
      <section className="relative mx-auto flex max-w-5xl flex-col items-center gap-8 px-6 pb-16 pt-20 text-center sm:pt-28">
        <Reveal>
          <span className="inline-flex items-center gap-2 rounded-full border border-border bg-surface px-4 py-1.5 font-heading text-xs font-medium text-primary shadow-sm">
            🔋 modo contingência
          </span>
        </Reveal>

        <Reveal delay={0.05}>
          <Mascot mood="happy" className="h-40 w-40 animate-float text-primary sm:h-48 sm:w-48" />
        </Reveal>

        <Reveal delay={0.1}>
          <h1 className="font-heading text-4xl font-semibold leading-tight text-foreground sm:text-5xl md:text-6xl">
            Quando os créditos acabam,{" "}
            <span className="text-primary">o código continua.</span>
          </h1>
        </Reveal>

        <Reveal delay={0.15}>
          <p className="max-w-2xl text-balance text-base text-foreground/70 sm:text-lg">
            Um setup de IA de código <strong>rodando local, na sua GPU</strong>, pra
            você não ficar travado no meio de um projeto só porque o Claude Code, o
            Codex e o Antigravity ficaram sem tokens ao mesmo tempo.
          </p>
        </Reveal>

        <Reveal delay={0.2} className="flex flex-wrap items-center justify-center gap-3">
          <a
            href="https://github.com/BrunoHoinacki/local-ia-contingencia"
            target="_blank"
            rel="noopener noreferrer"
            className="rounded-full bg-primary px-6 py-3 font-heading text-sm font-semibold text-white shadow-[var(--card-shadow)] transition hover:-translate-y-0.5 hover:bg-primary-strong"
          >
            Ver no GitHub
          </a>
          <a
            href="#como-funciona"
            className="rounded-full border border-border bg-surface px-6 py-3 font-heading text-sm font-semibold text-foreground transition hover:-translate-y-0.5"
          >
            Como funciona
          </a>
        </Reveal>

        <Reveal delay={0.25}>
          <CopyCommand />
        </Reveal>
      </section>

      {/* PROBLEMA */}
      <section className="relative mx-auto max-w-5xl px-6 py-20">
        <Reveal className="mx-auto mb-12 max-w-2xl text-center">
          <h2 className="font-heading text-3xl font-semibold sm:text-4xl">
            O problema é sempre o mesmo horário
          </h2>
          <p className="mt-3 text-foreground/70">
            No meio de uma tarefa importante, os créditos acabam — e nem sempre só
            de uma ferramenta.
          </p>
        </Reveal>

        <div className="grid gap-5 sm:grid-cols-3">
          {TOOLS_SEM_CREDITO.map((tool, i) => (
            <Reveal key={tool.nome} delay={i * 0.08}>
              <div className="flex h-full flex-col items-center gap-3 rounded-2xl border border-border bg-surface p-6 text-center shadow-[var(--card-shadow)]">
                <span className="font-heading text-lg font-semibold">
                  {tool.nome}
                </span>
                <span className="inline-flex items-center gap-1.5 rounded-full bg-red-500/10 px-3 py-1 text-xs font-semibold text-red-500">
                  ⛔ {tool.motivo}
                </span>
              </div>
            </Reveal>
          ))}
        </div>

        <Reveal delay={0.3} className="mt-10 flex justify-center">
          <div className="flex items-center gap-4 rounded-2xl border border-border bg-surface px-6 py-5 shadow-[var(--card-shadow)]">
            <Mascot mood="tired" className="h-16 w-16 shrink-0 text-primary" />
            <p className="text-left text-sm text-foreground/70 sm:text-base">
              E aí é isso: <strong>zero ferramenta de IA disponível</strong>, projeto
              parado até os limites renovarem.
            </p>
          </div>
        </Reveal>
      </section>

      {/* SOLUÇÃO / STACK */}
      <section id="como-funciona" className="relative mx-auto max-w-5xl px-6 py-20">
        <Reveal className="mx-auto mb-12 max-w-2xl text-center">
          <h2 className="font-heading text-3xl font-semibold sm:text-4xl">
            A solução: uma IA de fallback, na sua própria máquina
          </h2>
          <p className="mt-3 text-foreground/70">
            Sem depender de nuvem, sem depender de créditos. Só a sua GPU AMD
            fazendo o trabalho.
          </p>
        </Reveal>

        <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
          {STACK.map((item, i) => (
            <Reveal key={item.nome} delay={i * 0.07}>
              <div className="flex h-full flex-col gap-2 rounded-2xl border border-border bg-surface p-6 shadow-[var(--card-shadow)]">
                <span className="font-heading text-base font-semibold text-primary">
                  {item.nome}
                </span>
                <span className="text-sm text-foreground/65">{item.desc}</span>
              </div>
            </Reveal>
          ))}
        </div>
      </section>

      {/* COMO USAR / PASSOS */}
      <section className="relative mx-auto max-w-4xl px-6 py-20">
        <Reveal className="mx-auto mb-12 max-w-2xl text-center">
          <h2 className="font-heading text-3xl font-semibold sm:text-4xl">
            3 passos e você já tá codando de novo
          </h2>
        </Reveal>

        <div className="flex flex-col gap-6">
          {PASSOS.map((passo, i) => (
            <Reveal key={passo.numero} delay={i * 0.1}>
              <div className="flex flex-col gap-3 rounded-2xl border border-border bg-surface p-6 shadow-[var(--card-shadow)] sm:flex-row sm:items-center sm:gap-6">
                <span className="font-heading flex h-12 w-12 shrink-0 items-center justify-center rounded-full bg-primary text-xl font-semibold text-white">
                  {passo.numero}
                </span>
                <div className="flex-1">
                  <h3 className="font-heading text-lg font-semibold">
                    {passo.titulo}
                  </h3>
                  <p className="mt-1 text-sm text-foreground/65">{passo.desc}</p>
                </div>
                <code className="shrink-0 rounded-lg bg-[#1c1330] px-3 py-2 font-mono text-xs text-mint">
                  {passo.comando}
                </code>
              </div>
            </Reveal>
          ))}
        </div>
      </section>

      {/* DISCLAIMER HONESTO */}
      <section className="relative mx-auto max-w-3xl px-6 py-20">
        <Reveal>
          <div className="flex flex-col items-center gap-4 rounded-3xl border border-border bg-surface px-8 py-10 text-center shadow-[var(--card-shadow)]">
            <Mascot mood="happy" className="h-20 w-20 text-primary" />
            <h3 className="font-heading text-2xl font-semibold">
              Um combinado antes de continuar
            </h3>
            <p className="max-w-lg text-sm text-foreground/70 sm:text-base">
              Esse modelo local <strong>não é páreo</strong> pras ferramentas pagas —
              é bem menor e mais limitado. Mas é o suficiente pra destravar tarefas
              simples e não deixar o projeto 100% parado enquanto os créditos não
              voltam. Contingência é isso: não precisa ser perfeito, precisa estar
              disponível.
            </p>
          </div>
        </Reveal>
      </section>

      {/* FOOTER */}
      <footer className="relative mx-auto flex max-w-5xl flex-col items-center gap-4 px-6 pb-16 pt-4 text-center">
        <PoweredByForcoder />
        <p className="text-xs text-foreground/45">
          Feito por{" "}
          <a
            href="https://github.com/BrunoHoinacki"
            target="_blank"
            rel="noopener noreferrer"
            className="underline decoration-dotted underline-offset-2 hover:text-foreground/70"
          >
            Bruno Hoinacki
          </a>{" "}
          · código aberto no{" "}
          <a
            href="https://github.com/BrunoHoinacki/local-ia-contingencia"
            target="_blank"
            rel="noopener noreferrer"
            className="underline decoration-dotted underline-offset-2 hover:text-foreground/70"
          >
            GitHub
          </a>
        </p>
      </footer>
    </main>
  );
}
