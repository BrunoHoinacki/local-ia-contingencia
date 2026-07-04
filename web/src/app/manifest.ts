import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "IA Local de Contingência",
    short_name: "IA Local",
    description:
      "Setup de IA de código local (Ollama + ROCm) para fallback quando Claude Code, Codex ou Antigravity ficam sem créditos.",
    start_url: "/",
    display: "standalone",
    background_color: "#fdf6ec",
    theme_color: "#7c3aed",
    icons: [
      { src: "/icon", sizes: "32x32", type: "image/png" },
      { src: "/apple-icon", sizes: "180x180", type: "image/png" },
    ],
  };
}
