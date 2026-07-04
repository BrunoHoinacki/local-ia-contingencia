import Image from "next/image";

export function PoweredByForcoder() {
  return (
    <a
      href="https://forcoder.com.br"
      target="_blank"
      rel="noopener noreferrer"
      className="inline-flex items-center gap-2 rounded-full border border-border bg-surface px-4 py-2 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
    >
      <span className="font-heading text-[11px] uppercase tracking-wide text-foreground/50">
        powered by
      </span>
      <Image
        src="/brand/forcoder-black.png"
        alt="ForCoder"
        width={92}
        height={20}
        className="h-4 w-auto dark:hidden"
      />
      <Image
        src="/brand/forcoder-white.png"
        alt="ForCoder"
        width={92}
        height={20}
        className="hidden h-4 w-auto dark:block"
      />
    </a>
  );
}
