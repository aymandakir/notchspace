#!/usr/bin/env swift
//
// GenerateIcon.swift
// Run from the repo root:  swift Scripts/GenerateIcon.swift
//
// Requires macOS 12+ (for SF Symbol with configuration).
// Outputs PNG files to Sources/App/Resources/Assets.xcassets/AppIcon.appiconset/

import AppKit
import CoreGraphics

// ─── Output directory ────────────────────────────────────────────────────────

let repoRoot   = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let outputDir  = repoRoot
    .appendingPathComponent("Sources/App/Resources/Assets.xcassets/AppIcon.appiconset")

// ─── Icon renderer ────────────────────────────────────────────────────────────
//
// Visual design
//   • Deep space-black rounded square
//   • White notch pill near the top (like the hardware notch)
//   • Electric-blue bolt.fill SF Symbol below the pill

func renderIcon(size: Int) -> NSImage {
    let s    = CGFloat(size)
    let img  = NSImage(size: NSSize(width: s, height: s))
    img.lockFocus()
    defer { img.unlockFocus() }

    let ctx  = NSGraphicsContext.current!.cgContext
    let rect = CGRect(x: 0, y: 0, width: s, height: s)

    // ── Background ───────────────────────────────────────────────────────────
    let radius = s * 0.22
    let bgPath = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    ctx.addPath(bgPath)
    ctx.setFillColor(CGColor(red: 0.04, green: 0.04, blue: 0.07, alpha: 1))
    ctx.fillPath()

    // Subtle gradient overlay on the background
    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            CGColor(red: 0.10, green: 0.10, blue: 0.18, alpha: 0.6),
            CGColor(red: 0.02, green: 0.02, blue: 0.05, alpha: 0.8),
        ] as CFArray,
        locations: [0, 1]
    )!
    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()
    ctx.drawLinearGradient(gradient,
        start: CGPoint(x: s * 0.5, y: s),
        end:   CGPoint(x: s * 0.5, y: 0),
        options: []
    )
    ctx.restoreGState()

    // ── Notch pill ────────────────────────────────────────────────────────────
    let pillW: CGFloat = s * 0.50
    let pillH: CGFloat = s * 0.16
    let pillX: CGFloat = (s - pillW) / 2
    let pillY: CGFloat = s * 0.66
    let pillR           = pillH / 2
    let pillRect        = CGRect(x: pillX, y: pillY, width: pillW, height: pillH)

    // Fill
    ctx.addPath(CGPath(roundedRect: pillRect, cornerWidth: pillR, cornerHeight: pillR, transform: nil))
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.12))
    ctx.fillPath()

    // Stroke
    let pillStroke = pillRect.insetBy(dx: s * 0.006, dy: s * 0.006)
    ctx.addPath(CGPath(roundedRect: pillStroke, cornerWidth: pillR, cornerHeight: pillR, transform: nil))
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.45))
    ctx.setLineWidth(max(1, s * 0.009))
    ctx.strokePath()

    // ── Bolt SF Symbol ────────────────────────────────────────────────────────
    let symbolPt  = s * 0.28
    let symConfig = NSImage.SymbolConfiguration(pointSize: symbolPt, weight: .semibold)
    if let bolt   = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: nil)?
                        .withSymbolConfiguration(symConfig) {
        // Tint to electric blue by drawing with a color overlay
        let symW = bolt.size.width
        let symH = bolt.size.height
        let symX = (s - symW) / 2
        let symY = s * 0.16

        NSGraphicsContext.current?.imageInterpolation = .high

        // Draw a blue tinted version using compositing
        NSColor(calibratedRed: 0.30, green: 0.60, blue: 1.0, alpha: 0.90).setFill()
        let symRect = NSRect(x: symX, y: symY, width: symW, height: symH)

        // Draw into a temporary image so we can apply color
        let tinted = NSImage(size: bolt.size)
        tinted.lockFocus()
        NSColor(calibratedRed: 0.30, green: 0.60, blue: 1.0, alpha: 0.90).set()
        bolt.draw(at: .zero, from: .zero, operation: .sourceAtop, fraction: 1.0)
        tinted.unlockFocus()
        tinted.draw(in: symRect, from: .zero, operation: .sourceOver, fraction: 1.0)
    }

    // ── Inner glow border ─────────────────────────────────────────────────────
    ctx.addPath(bgPath.copy(strokingWithWidth: max(1, s * 0.01),
                             lineCap: .butt, lineJoin: .miter, miterLimit: 1))
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.07))
    ctx.fillPath()

    return img
}

// ─── Write PNGs ───────────────────────────────────────────────────────────────

let sizes: [(Int, String)] = [
    (16,   "AppIcon-16.png"),
    (32,   "AppIcon-32.png"),
    (64,   "AppIcon-64.png"),
    (128,  "AppIcon-128.png"),
    (256,  "AppIcon-256.png"),
    (512,  "AppIcon-512.png"),
    (1024, "AppIcon-1024.png"),
]

try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

for (size, filename) in sizes {
    let image = renderIcon(size: size)
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:])
    else {
        print("⚠️  Failed to render \(filename)")
        continue
    }
    let dest = outputDir.appendingPathComponent(filename)
    try png.write(to: dest)
    print("✓  \(filename)  (\(size)×\(size))")
}

print("\nDone — run 'open Package.swift' in Xcode to verify the icon.")
