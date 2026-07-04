import { ImageResponse } from "next/og";

export const size = { width: 32, height: 32 };
export const contentType = "image/png";

export default function Icon() {
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
          borderRadius: 8,
        }}
      >
        <div
          style={{
            width: 18,
            height: 14,
            border: "3px solid white",
            borderRadius: 3,
            display: "flex",
            alignItems: "center",
            padding: 2,
          }}
        >
          <div style={{ width: 10, height: 8, background: "#5eead4", borderRadius: 1 }} />
        </div>
      </div>
    ),
    { ...size }
  );
}
