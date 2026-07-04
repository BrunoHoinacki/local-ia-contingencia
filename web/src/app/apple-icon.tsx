import { ImageResponse } from "next/og";

export const size = { width: 180, height: 180 };
export const contentType = "image/png";

export default function AppleIcon() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          background: "#7c3aed",
        }}
      >
        <div
          style={{
            width: 96,
            height: 76,
            border: "14px solid white",
            borderRadius: 18,
            display: "flex",
            alignItems: "center",
            padding: 10,
          }}
        >
          <div style={{ width: 56, height: 44, background: "#5eead4", borderRadius: 6 }} />
        </div>
      </div>
    ),
    { ...size }
  );
}
