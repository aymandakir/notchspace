#!/usr/bin/env swift
// GenerateIcon.swift
// Generates all macOS AppIcon sizes for NotchSpace.
// Run: swift Scripts/GenerateIcon.swift
//
// Design: space-black rounded square, white notch pill (slightly above centre),
//         electric-blue bolt inside the pill, dual aurora glow (purple left /
//         blue right) at ~15 % opacity so the overall feel stays dark & minimal.

import CoreGraphics
import ImageIO
import Foundation
import CryptoKit

// ── Output path ───────────────────────────────────────────────────────────────

let outputDir = "Sources/App/Resources/Assets.xcassets/AppIcon.appiconset"

// ── Colour helpers ────────────────────────────────────────────────────────────

let cs = CGColorSpaceCreateDeviceRGB()

func col(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: cs, components: [r, g, b, a])!
}

// Palette
let spaceBlack   = col(0.039, 0.039, 0.059)          // #0A0A0F
let pillFill     = col(1, 1, 1, 0.10)
let pillStroke   = col(1, 1, 1, 0.55)
let boltBlue     = col(0.000, 0.659, 1.000, 0.95)    // #00A8FF
let boltGlow     = col(0.000, 0.659, 1.000, 0.35)
let purpleGlow0  = col(0.239, 0.102, 0.431, 0.15)    // #3D1A6E
let purpleGlow1  = col(0.239, 0.102, 0.431, 0.00)
let blueGlow0    = col(0.000, 0.659, 1.000, 0.15)
let blueGlow1    = col(0.000, 0.659, 1.000, 0.00)

// ── Renderer ──────────────────────────────────────────────────────────────────

func renderIcon(size: Int) -> CGImage {
    let s = CGFloat(size)

    guard let ctx = CGContext(
        data: nil, width: size, height: size,
        bitsPerComponent: 8, bytesPerRow: 0, space: cs,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { fatalError("CGContext creation failed") }

    let rect    = CGRect(x: 0, y: 0, width: s, height: s)
    let corner  = s * 0.225          // macOS icon corner radius ≈ 22.5 %

    // ── Clip to macOS rounded square ──────────────────────────────────────────
    let bgPath = CGMutablePath()
    bgPath.addRoundedRect(in: rect, cornerWidth: corner, cornerHeight: corner)
    ctx.addPath(bgPath)
    ctx.clip()

    // ── Space-black background ────────────────────────────────────────────────
    ctx.setFillColor(spaceBlack)
    ctx.fill(rect)

    // ── Aurora glow — purple (left) ───────────────────────────────────────────
    let glowR = s * 0.58
    let pg = CGGradient(colorsSpace: cs,
                        colors: [purpleGlow0, purpleGlow1] as CFArray,
                        locations: [0, 1])!
    ctx.drawRadialGradient(pg,
        startCenter: CGPoint(x: s * 0.30, y: s * 0.53), startRadius: 0,
        endCenter:   CGPoint(x: s * 0.30, y: s * 0.53), endRadius: glowR,
        options: [])

    // ── Aurora glow — blue (right) ────────────────────────────────────────────
    let bg = CGGradient(colorsSpace: cs,
                        colors: [blueGlow0, blueGlow1] as CFArray,
                        locations: [0, 1])!
    ctx.drawRadialGradient(bg,
        startCenter: CGPoint(x: s * 0.70, y: s * 0.53), startRadius: 0,
        endCenter:   CGPoint(x: s * 0.70, y: s * 0.53), endRadius: glowR,
        options: [])

    // ── Pill (notch shape) ────────────────────────────────────────────────────
    let pillW  = s * 0.40
    let pillH  = max(CGFloat(size >= 32 ? 4 : 2), s * 0.135)
    let pillX  = (s - pillW) / 2
    let pillY  = (s - pillH) / 2 + s * 0.025     // slightly above centre
    let pillR  = pillH / 2
    let pillRt = CGRect(x: pillX, y: pillY, width: pillW, height: pillH)

    let pillPath = CGMutablePath()
    pillPath.addRoundedRect(in: pillRt, cornerWidth: pillR, cornerHeight: pillR)

    ctx.setFillColor(pillFill)
    ctx.addPath(pillPath); ctx.fillPath()

    ctx.setStrokeColor(pillStroke)
    ctx.setLineWidth(max(0.5, s * 0.007))
    ctx.addPath(pillPath); ctx.strokePath()

    // ── Electric-blue bolt ────────────────────────────────────────────────────
    guard size >= 16 else { return ctx.makeImage()! }

    let bH  = pillH * 0.70          // bolt height
    let bW  = bH * 0.58             // bolt width
    let cx  = s / 2
    let cy  = pillY + pillH / 2     // centre of pill
    let hH  = bH / 2
    let hW  = bW / 2

    // Six-point lightning-bolt polygon (CG y-axis: 0 = bottom)
    //
    //     P1 ──┐
    //     P6   P2
    //     └──  P3
    //          │
    //     P5   P4
    //     └────┘
    //
    let bolt = CGMutablePath()
    bolt.move(to:    CGPoint(x: cx + hW * 0.65,  y: cy + hH))          // P1 top-right
    bolt.addLine(to: CGPoint(x: cx - hW * 0.12,  y: cy + hH * 0.10))  // P2 step-left
    bolt.addLine(to: CGPoint(x: cx + hW * 0.30,  y: cy + hH * 0.10))  // P3 step-right
    bolt.addLine(to: CGPoint(x: cx - hW * 0.65,  y: cy - hH))         // P4 bottom-left
    bolt.addLine(to: CGPoint(x: cx + hW * 0.12,  y: cy - hH * 0.10))  // P5 step-right
    bolt.addLine(to: CGPoint(x: cx - hW * 0.30,  y: cy - hH * 0.10))  // P6 step-left
    bolt.closeSubpath()

    // Soft glow behind bolt (larger sizes only)
    if size >= 64 {
        let bg2 = CGGradient(colorsSpace: cs,
                             colors: [boltGlow, col(0, 0.659, 1, 0)] as CFArray,
                             locations: [0, 1])!
        ctx.drawRadialGradient(bg2,
            startCenter: CGPoint(x: cx, y: cy), startRadius: 0,
            endCenter:   CGPoint(x: cx, y: cy), endRadius: pillH * 1.4,
            options: [])
    }

    ctx.setFillColor(boltBlue)
    ctx.addPath(bolt); ctx.fillPath()

    return ctx.makeImage()!
}

// ── Save PNG ──────────────────────────────────────────────────────────────────

func savePNG(_ image: CGImage, path: String) {
    let url  = URL(fileURLWithPath: path)
    guard let dest = CGImageDestinationCreateWithURL(
        url as CFURL, "public.png" as CFString, 1, nil
    ) else { fatalError("Cannot create PNG destination: \(path)") }
    CGImageDestinationAddImage(dest, image, nil)
    guard CGImageDestinationFinalize(dest) else {
        fatalError("CGImageDestinationFinalize failed: \(path)")
    }
}

// ── Generate all sizes ────────────────────────────────────────────────────────

let sizes: [(Int, String)] = [
    (16,   "AppIcon-16"),
    (32,   "AppIcon-32"),
    (64,   "AppIcon-64"),
    (128,  "AppIcon-128"),
    (256,  "AppIcon-256"),
    (512,  "AppIcon-512"),
    (1024, "AppIcon-1024"),
]

try! FileManager.default.createDirectory(
    atPath: outputDir, withIntermediateDirectories: true
)

for (px, name) in sizes {
    let path = "\(outputDir)/\(name).png"
    savePNG(renderIcon(size: px), path: path)
    print("✓  \(name).png  (\(px)×\(px))")
}

// ── Update Contents.json ──────────────────────────────────────────────────────

let contentsJSON = """
{
  "images" : [
    { "idiom" : "mac", "scale" : "1x", "size" : "16x16",   "filename" : "AppIcon-16.png"   },
    { "idiom" : "mac", "scale" : "2x", "size" : "16x16",   "filename" : "AppIcon-32.png"   },
    { "idiom" : "mac", "scale" : "1x", "size" : "32x32",   "filename" : "AppIcon-32.png"   },
    { "idiom" : "mac", "scale" : "2x", "size" : "32x32",   "filename" : "AppIcon-64.png"   },
    { "idiom" : "mac", "scale" : "1x", "size" : "128x128", "filename" : "AppIcon-128.png"  },
    { "idiom" : "mac", "scale" : "2x", "size" : "128x128", "filename" : "AppIcon-256.png"  },
    { "idiom" : "mac", "scale" : "1x", "size" : "256x256", "filename" : "AppIcon-256.png"  },
    { "idiom" : "mac", "scale" : "2x", "size" : "256x256", "filename" : "AppIcon-512.png"  },
    { "idiom" : "mac", "scale" : "1x", "size" : "512x512", "filename" : "AppIcon-512.png"  },
    { "idiom" : "mac", "scale" : "2x", "size" : "512x512", "filename" : "AppIcon-1024.png" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
"""

let jsonPath = "\(outputDir)/Contents.json"
try! contentsJSON.write(toFile: jsonPath, atomically: true, encoding: .utf8)
print("✓  Contents.json updated")

// ── SHA-256 of 1024 px file ───────────────────────────────────────────────────

let bigURL  = URL(fileURLWithPath: "\(outputDir)/AppIcon-1024.png")
let bigData = try! Data(contentsOf: bigURL)
let hash    = SHA256.hash(data: bigData)
let hexHash = hash.compactMap { String(format: "%02x", $0) }.joined()
print("\nSHA-256 (AppIcon-1024.png): \(hexHash)")
