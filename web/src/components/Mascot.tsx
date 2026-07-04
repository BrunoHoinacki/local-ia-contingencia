type MascotProps = {
  className?: string;
  mood?: "happy" | "tired";
};

export function Mascot({ className, mood = "happy" }: MascotProps) {
  return (
    <svg
      viewBox="0 0 240 240"
      className={className}
      role="img"
      aria-label={
        mood === "happy"
          ? "Robô mascote sorrindo com a bateria cheia"
          : "Robô mascote cansado com a bateria vazia"
      }
    >
      <ellipse cx="120" cy="222" rx="58" ry="10" fill="currentColor" opacity="0.08" />

      {/* antenna */}
      <g className="origin-[120px_46px] animate-wiggle">
        <line x1="120" y1="46" x2="120" y2="24" stroke="var(--accent)" strokeWidth="6" strokeLinecap="round" />
        <circle cx="120" cy="18" r="9" fill="var(--accent)" />
      </g>

      {/* head */}
      <rect x="58" y="46" width="124" height="94" rx="30" fill="var(--surface)" stroke="var(--primary)" strokeWidth="6" />

      {/* ears */}
      <rect x="42" y="76" width="16" height="34" rx="8" fill="var(--primary)" />
      <rect x="182" y="76" width="16" height="34" rx="8" fill="var(--primary)" />

      {/* eyes */}
      <g className="animate-blink">
        {mood === "happy" ? (
          <>
            <circle cx="97" cy="90" r="10" fill="var(--primary)" />
            <circle cx="143" cy="90" r="10" fill="var(--primary)" />
          </>
        ) : (
          <>
            <line x1="88" y1="90" x2="106" y2="90" stroke="var(--primary)" strokeWidth="6" strokeLinecap="round" />
            <line x1="134" y1="90" x2="152" y2="90" stroke="var(--primary)" strokeWidth="6" strokeLinecap="round" />
          </>
        )}
      </g>

      {/* mouth */}
      {mood === "happy" ? (
        <path d="M100 112 Q120 128 140 112" stroke="var(--accent-strong)" strokeWidth="6" fill="none" strokeLinecap="round" />
      ) : (
        <path d="M100 118 Q120 108 140 118" stroke="var(--accent-strong)" strokeWidth="6" fill="none" strokeLinecap="round" />
      )}

      {/* cheeks */}
      <circle cx="80" cy="106" r="7" fill="var(--accent)" opacity="0.5" />
      <circle cx="160" cy="106" r="7" fill="var(--accent)" opacity="0.5" />

      {/* body */}
      <rect x="72" y="150" width="96" height="64" rx="24" fill="var(--surface)" stroke="var(--primary)" strokeWidth="6" />

      {/* battery on chest */}
      <rect x="98" y="166" width="44" height="26" rx="6" fill="none" stroke="var(--mint)" strokeWidth="5" />
      <rect x="142" y="174" width="6" height="10" rx="2" fill="var(--mint)" />
      <rect
        x="102"
        y="170"
        width={mood === "happy" ? 36 : 12}
        height="18"
        rx="3"
        fill="var(--mint)"
      />

      {/* arms */}
      <rect x="46" y="158" width="18" height="40" rx="9" fill="var(--primary)" opacity="0.85" />
      <rect x="176" y="158" width="18" height="40" rx="9" fill="var(--primary)" opacity="0.85" />
    </svg>
  );
}
