"use client";

import { useState } from "react";

const COMMAND =
  "git clone https://github.com/BrunoHoinacki/local-ia-contingencia.git && cd local-ia-contingencia && bash tools.sh";

export function CopyCommand() {
  const [copied, setCopied] = useState(false);

  async function handleCopy() {
    try {
      await navigator.clipboard.writeText(COMMAND);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      // clipboard indisponível, o usuário ainda pode selecionar o texto manualmente
    }
  }

  return (
    <div className="w-full max-w-2xl rounded-2xl border border-border bg-[#1c1330] shadow-[var(--card-shadow)] overflow-hidden">
      <div className="flex items-center gap-2 px-4 py-3 bg-[#140c22]">
        <span className="h-3 w-3 rounded-full bg-[#ff5f57]" />
        <span className="h-3 w-3 rounded-full bg-[#ffbd2e]" />
        <span className="h-3 w-3 rounded-full bg-[#28c840]" />
        <span className="ml-3 font-heading text-xs text-white/50">
          terminal
        </span>
      </div>
      <div className="flex flex-col gap-3 px-4 py-4 sm:flex-row sm:items-center">
        <code className="min-w-0 flex-1 break-all font-mono text-[13px] leading-relaxed text-mint sm:whitespace-nowrap sm:overflow-x-auto sm:break-normal sm:text-sm">
          <span className="text-white/40">$ </span>
          {COMMAND}
        </code>
        <button
          onClick={handleCopy}
          className="shrink-0 rounded-lg bg-primary px-3 py-2 text-xs font-semibold text-white transition hover:bg-primary-strong active:scale-95 sm:text-sm"
        >
          {copied ? "Copiado! ✓" : "Copiar"}
        </button>
      </div>
      <p className="border-t border-white/5 px-4 py-3 text-xs text-white/45">
        O <code className="text-mint">tools.sh</code> abre um menu: escolha{" "}
        <strong>1</strong> pra instalar o ROCm, reinicie o PC, rode{" "}
        <code className="text-mint">bash tools.sh</code> de novo e escolha{" "}
        <strong>2</strong> pra subir o Ollama e ganhar os atalhos{" "}
        <code className="text-mint">chat-ia</code> e{" "}
        <code className="text-mint">ia-cli</code>.
      </p>
    </div>
  );
}
