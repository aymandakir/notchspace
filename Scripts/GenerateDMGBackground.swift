#!/usr/bin/env swift
// GenerateDMGBackground.swift
// Generates the 660×400 DMG installer background.
// Run: swift Scripts/GenerateDMGBackground.swift
//
// Output: Scripts/dmg-background.png

import AppKit

let W: CGFloat = 660
let H: CGFloat = 400

let image = NSImage(size: NSSize(width: W, height: H))
image.lockFocus()
defer { image.unlockFocus() }

guard let ctx = NSGraphicsContext.current?.cgContext else { exit(1) }

// ── Background ────────────────────────────────────────────────────────────────
let bgColors = [
    CGColor(red: 0.055, green: 0.055, blue: 0.095, alpha: 1),   // top
    CGColor(red: 0.035, green: 0.035, blue: 0.060, alpha: 1),   // bottom
] as CFArray
let bgGrad = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: bgColors,
    locations: [0, 1]
)!
ctx.drawLinearGradient(bgGrad,
    start: CGPoint(x: W / 2, y: H),
    end:   CGPoint(x: W / 2, y: 0),
    options: []
)

// ── Subtle top aurora glow ────────────────────────────────────────────────────
let glowColors = [
    CGColor(red: 0.18, green: 0.10, blue: 0.55, alpha: 0.35),
    CGColor(red: 0.00, green: 0.10, blue: 0.50, alpha: 0.15),
    CGColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 0.00),
] as CFArray
let glowLocs: [CGFloat] = [0, 0.4, 1]
let glowGrad = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: glowColors,
    locations: glowLocs
)!
ctx.drawRadialGradient(glowGrad,
    startCenter: CGPoint(x: W / 2, y: H + 20),
    startRadius: 0,
    endCenter:   CGPoint(x: W / 2, y: H + 20),
    endRadius:   W * 0.75,
    options: []
)

// ── Horizontal separator line ─────────────────────────────────────────────────
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.06))
ctx.setLineWidth(1)
ctx.move(to:    CGPoint(x: 40,     y: H / 2))
ctx.addLine(to: CGPoint(x: W - 40, y: H / 2))
ctx.strokePath()

// ── Icon zone circles (guide rings where create-dmg places icons) ─────────────
func drawIconZone(_ cx: CGFloat, _ cy: CGFloat) {
    let r: CGFloat = 66
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.05))
    ctx.setLineWidth(1)
    ctx.strokeEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
}
drawIconZone(165, 220)
drawIconZone(495, 220)

// ── Arrow ─────────────────────────────────────────────────────────────────────
// Horizontal arrow from x=255 to x=405, centred at y=220
let arrowY: CGFloat = 220
let ax0:    CGFloat = 262
let ax1:    CGFloat = 398
let headW:  CGFloat = 14
let headH:  CGFloat = 10
let shaftH: CGFloat = 3

ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.18))

// Shaft
ctx.fill(CGRect(x: ax0, y: arrowY - shaftH / 2,
                width: ax1 - ax0 - headW, height: shaftH))

// Arrowhead
let tip = CGPoint(x: ax1, y: arrowY)
let arrowPath = CGMutablePath()
arrowPath.move(to: tip)
arrowPath.addLine(to: CGPoint(x: ax1 - headW, y: arrowY + headH / 2))
arrowPath.addLine(to: CGPoint(x: ax1 - headW, y: arrowY - headH / 2))
arrowPath.closeSubpath()
ctx.addPath(arrowPath)
ctx.fillPath()

// ── "NotchSpace" wordmark (left zone, below icon) ────────────────────────────
let titlePara = NSMutableParagraphStyle()
titlePara.alignment = .center

let titleStr = NSAttributedString(string: "NotchSpace", attributes: [
    .font: NSFont.systemFont(ofSize: 17, weight: .semibold),
    .foregroundColor: NSColor.white.withAlphaComponent(0.88),
    .paragraphStyle: titlePara,
])
titleStr.draw(in: CGRect(x: 65, y: 132, width: 200, height: 24))

let tagStr = NSAttributedString(string: "Live inside your notch", attributes: [
    .font: NSFont.systemFont(ofSize: 11, weight: .regular),
    .foregroundColor: NSColor.white.withAlphaComponent(0.32),
    .paragraphStyle: titlePara,
])
tagStr.draw(in: CGRect(x: 65, y: 112, width: 200, height: 18))

// ── "Applications" label (right zone, below icon) ────────────────────────────
let appStr = NSAttributedString(string: "Applications", attributes: [
    .font: NSFont.systemFont(ofSize: 13, weight: .medium),
    .foregroundColor: NSColor.white.withAlphaComponent(0.45),
    .paragraphStyle: titlePara,
])
appStr.draw(in: CGRect(x: 395, y: 138, width: 200, height: 20))

// ── Bottom instruction ────────────────────────────────────────────────────────
let instrPara = NSMutableParagraphStyle()
instrPara.alignment = .center
let instrStr = NSAttributedString(
    string: "Drag NotchSpace to the Applications folder to install",
    attributes: [
        .font: NSFont.systemFont(ofSize: 11, weight: .regular),
        .foregroundColor: NSColor.white.withAlphaComponent(0.22),
        .paragraphStyle: instrPara,
    ]
)
instrStr.draw(in: CGRect(x: 40, y: 28, width: W - 80, height: 18))

// ── Version badge ─────────────────────────────────────────────────────────────
let verStr = NSAttributedString(string: "v1.0.0", attributes: [
    .font: NSFont.monospacedSystemFont(ofSize: 9.5, weight: .regular),
    .foregroundColor: NSColor.white.withAlphaComponent(0.18),
    .paragraphStyle: instrPara,
])
verStr.draw(in: CGRect(x: W - 80, y: 12, width: 60, height: 14))

// ── Save PNG ──────────────────────────────────────────────────────────────────
guard let tiff   = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png    = bitmap.representation(using: .png, properties: [:])
else { fatalError("Failed to render background") }

let out = URL(fileURLWithPath: "Scripts/dmg-background.png")
try! png.write(to: out)
print("✓  \(out.path)  (\(Int(W))×\(Int(H)))")
