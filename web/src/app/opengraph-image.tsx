import { ImageResponse } from "next/og";

export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export default function Image() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          gap: 28,
          background: "linear-gradient(135deg, #241b2f 0%, #3b1f63 55%, #7c3aed 100%)",
          fontFamily: "sans-serif",
        }}
      >
        <div
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            width: 160,
            height: 160,
            borderRadius: 40,
            background: "#ffffff",
            border: "8px solid #a780ff",
          }}
        >
          <div
            style={{
              width: 90,
              height: 70,
              border: "10px solid #7c3aed",
              borderRadius: 16,
              display: "flex",
              alignItems: "center",
              padding: 8,
            }}
          >
            <div style={{ width: 54, height: 40, background: "#2dd4bf", borderRadius: 6 }} />
          </div>
        </div>
        <div
          style={{
            fontSize: 60,
            fontWeight: 700,
            color: "white",
            textAlign: "center",
            padding: "0 60px",
          }}
        >
          Quando os créditos acabam,
        </div>
        <div
          style={{
            fontSize: 60,
            fontWeight: 700,
            color: "#ffb35c",
            textAlign: "center",
            marginTop: -20,
          }}
        >
          o código continua.
        </div>
        <div style={{ fontSize: 26, color: "#e6d9ff", marginTop: 4 }}>
          IA de código local · Ollama + ROCm · ia-local.forcoder.com.br
        </div>
      </div>
    ),
    { ...size }
  );
}
