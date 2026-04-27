import { ImageResponse } from "next/og";

export const size = {
  width: 1200,
  height: 630,
};

export const contentType = "image/png";

export default function OpengraphImage() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          position: "relative",
          background: "#07080c",
          color: "#f4f4f5",
          fontFamily: "Inter, system-ui, sans-serif",
          padding: "56px",
        }}
      >
        <div
          style={{
            position: "absolute",
            top: "-140px",
            left: "50%",
            transform: "translateX(-50%)",
            width: "520px",
            height: "520px",
            borderRadius: "999px",
            background: "rgba(139, 92, 246, 0.24)",
            filter: "blur(80px)",
          }}
        />
        <div
          style={{
            border: "1px solid rgba(255,255,255,0.12)",
            borderRadius: "28px",
            background: "linear-gradient(180deg, rgba(255,255,255,0.09), rgba(255,255,255,0.04))",
            padding: "44px",
            display: "flex",
            flexDirection: "column",
            justifyContent: "space-between",
            width: "100%",
            height: "100%",
            position: "relative",
          }}
        >
          <div style={{ display: "flex", fontSize: 26, letterSpacing: "0.18em", fontWeight: 700 }}>
            RESONA
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
            <div style={{ display: "flex", fontSize: 64, lineHeight: 1.1, fontWeight: 700, maxWidth: "900px" }}>
              Open music streaming, your way
            </div>
            <div style={{ display: "flex", fontSize: 28, color: "rgba(244,244,245,0.82)" }}>
              Privacy-first. Smart discovery. Open-source.
            </div>
          </div>
        </div>
      </div>
    ),
    size,
  );
}
