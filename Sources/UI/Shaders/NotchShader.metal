#include <metal_stdlib>
using namespace metal;

// ─── Shared types ─────────────────────────────────────────────────────────────

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

struct AuroraUniforms {
    float time;       // seconds since shader start
    float intensity;  // 0 = barely visible, 1 = vivid
};

// ─── Vertex shader ────────────────────────────────────────────────────────────
//
// Single fullscreen triangle.  Three hard-coded vertices cover the entire
// clip-space square without needing a vertex buffer.

vertex VertexOut aurora_vert(uint vid [[vertex_id]]) {
    constexpr float2 pos[3] = {
        float2(-1.0, -1.0),
        float2( 3.0, -1.0),
        float2(-1.0,  3.0),
    };
    VertexOut out;
    out.position = float4(pos[vid], 0.0, 1.0);
    out.uv       = pos[vid] * 0.5 + 0.5;   // map NDC → [0, 1]
    return out;
}

// ─── Fragment shader ──────────────────────────────────────────────────────────
//
// Aurora / plasma effect built from four overlapping sin/cos interference
// fields.  The wave parameters were chosen to produce slow horizontal drifts
// with occasional diagonal ripples — evocative of northern-lights banding.
//
// Color palette (all very dark so the black notch is never overwhelmed):
//   c1  deep purple   (0.10, 0.00, 0.20)
//   c2  electric blue (0.00, 0.06, 0.42)
//   c3  subtle teal   (0.00, 0.16, 0.20)
//
// At intensity 0 the effect is a barely-perceptible shimmer (alpha ≈ 0.05).
// At intensity 1 it becomes a soft glow (alpha ≈ 0.42).

fragment float4 aurora_frag(
    VertexOut            in [[stage_in]],
    constant AuroraUniforms &u [[buffer(0)]]
) {
    // Aspect-corrected UV centred at origin.
    // Notch expanded dimensions: 500 × 132 → ratio ≈ 3.79
    float2 p = (in.uv - 0.5) * float2(3.79, 1.0);

    float t = u.time * 0.16;   // slow overall drift

    // ── Wave interference ─────────────────────────────────────────────────
    // Four fields with incommensurable frequencies prevent visible repetition.
    float v = 0.0;
    v += sin(p.x * 1.10 + t        + cos(p.y * 1.55 + t * 0.52));
    v += sin(p.y * 2.25 - t * 0.73 + sin(p.x * 0.92 + t * 0.41));
    v += sin((p.x - p.y) * 1.38    + t * 0.87);
    v += 0.55 * sin(length(p * float2(1.0, 2.4)) * 2.85 - t * 1.08);

    // Normalise to [0, 1]
    v = v / 3.55 * 0.5 + 0.5;
    float cv = saturate(v);

    // ── Color ramp ────────────────────────────────────────────────────────
    constexpr float3 c1 = float3(0.10, 0.00, 0.20);   // deep purple
    constexpr float3 c2 = float3(0.00, 0.06, 0.42);   // electric blue
    constexpr float3 c3 = float3(0.00, 0.16, 0.20);   // subtle teal

    float3 color = (cv < 0.5)
        ? mix(c1, c2, cv * 2.0)
        : mix(c2, c3, (cv - 0.5) * 2.0);

    // ── Vignette ──────────────────────────────────────────────────────────
    // Fade horizontally toward the left/right extremes and push toward the
    // top so the glow feels like it emanates from the notch.
    float vx = 1.0 - smoothstep(0.75, 1.0, abs(p.x) * 0.527);   // 0.527 = 1/1.9
    float vy = 1.0 - smoothstep(0.10, 0.65, abs(p.y) * 1.5 + 0.05);
    color *= vx * vy;

    // ── Intensity scaling ─────────────────────────────────────────────────
    // Brightness lift proportional to intensity so the hues stay saturated
    // even at low values rather than turning grey.
    float bright = 1.0 + u.intensity * 1.3;
    float alpha  = mix(0.048, 0.42, u.intensity);

    return float4(color * bright, alpha);
}
