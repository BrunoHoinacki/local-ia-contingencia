import type { Metadata, Viewport } from "next";
import { Fredoka, Inter } from "next/font/google";
import "./globals.css";

const fredoka = Fredoka({
  variable: "--font-fredoka",
  subsets: ["latin"],
  weight: ["500", "600", "700"],
});

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
});

const siteUrl = "https://ia-local.forcoder.com.br";
const title = "IA Local de Contingência — quando os créditos acabam, o código continua";
const description =
  "Setup open source de uma IA de código local (Ollama + ROCm + qwen2.5-coder), rodando na sua própria GPU AMD, para servir de fallback quando Claude Code, Codex ou Antigravity ficarem sem créditos.";

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: {
    default: title,
    template: "%s — IA Local de Contingência",
  },
  description,
  keywords: [
    "IA local",
    "Ollama",
    "ROCm",
    "AMD GPU",
    "qwen2.5-coder",
    "aider",
    "Claude Code",
    "Codex",
    "Antigravity",
    "fallback de IA",
    "IA de código offline",
    "self-hosted LLM",
  ],
  authors: [{ name: "Bruno Hoinacki", url: "https://github.com/BrunoHoinacki" }],
  creator: "Bruno Hoinacki",
  applicationName: "IA Local de Contingência",
  alternates: {
    canonical: siteUrl,
  },
  openGraph: {
    type: "website",
    locale: "pt_BR",
    url: siteUrl,
    siteName: "IA Local de Contingência",
    title,
    description,
    images: [
      {
        url: "/opengraph-image",
        width: 1200,
        height: 630,
        alt: "IA Local de Contingência — robô mascote com bateria carregando",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title,
    description,
    images: ["/opengraph-image"],
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-image-preview": "large",
    },
  },
  category: "technology",
};

export const viewport: Viewport = {
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#fdf6ec" },
    { media: "(prefers-color-scheme: dark)", color: "#181123" },
  ],
  colorScheme: "light dark",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="pt-BR"
      className={`${fredoka.variable} ${inter.variable} h-full antialiased`}
    >
      <body className="min-h-full flex flex-col">{children}</body>
    </html>
  );
}
