#!/usr/bin/env swift
// GenerateDMGBackground.swift — headless-safe (pure CoreGraphics, no NSImage)
// Run: swift Scripts/GenerateDMGBackground.swift

import CoreGraphics
import CoreText
import ImageIO
import Foundation

let W = 660
let H = 400

// ── Bitmap context ────────────────────────────────────────────────────────────

let cs  = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(
    data: nil, width: W, height: H,
    bitsPerComponent: 8, bytesPerRow: 0, space: cs,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { fatalError("Could not create CGContext") }

// CG origin is bottom-left; Y grows upward.

// ── Background gradient (top = dark navy, bottom = darker) ───────────────────

let bgColors = [
    CGColor(colorSpace: cs, components: [0.055, 0.055, 0.095, 1])!,
    CGColor(colorSpace: cs, components: [0.035, 0.035, 0.060, 1])!,
] as CFArray

let bgGrad = CGGradient(colorsSpace: cs, colors: bgColors, locations: [0, 1])!
ctx.drawLinearGradient(bgGrad,
    start: CGPoint(x: Double(W)/2, y: Double(H)),   // top
    end:   CGPoint(x: Double(W)/2, y: 0),           // bottom
    options: [])

// ── Subtle top aurora glow ────────────────────────────────────────────────────

let glowColors = [
    CGColor(colorSpace: cs, components: [0.18, 0.10, 0.55, 0.30])!,
    CGColor(colorSpace: cs, components: [0.00, 0.10, 0.50, 0.12])!,
    CGColor(colorSpace: cs, components: [0.00, 0.00, 0.00, 0.00])!,
] as CFArray
let glowLocs: [CGFloat] = [0, 0.45, 1]
let glowGrad = CGGradient(colorsSpace: cs, colors: glowColors, locations: glowLocs)!
ctx.drawRadialGradient(glowGrad,
    startCenter: CGPoint(x: Double(W)/2, y: Double(H) + 20), startRadius: 0,
    endCenter:   CGPoint(x: Double(W)/2, y: Double(H) + 20), endRadius: Double(W) * 0.75,
    options: [])

// ── Horizontal separator ──────────────────────────────────────────────────────

ctx.setStrokeColor(CGColor(colorSpace: cs, components: [1, 1, 1, 0.06])!)
ctx.setLineWidth(1)
ctx.move(to:    CGPoint(x: 40,     y: Double(H)/2))
ctx.addLine(to: CGPoint(x: Double(W)-40, y: Double(H)/2))
ctx.strokePath()

// ── Icon guide rings (where create-dmg places icons) ─────────────────────────

func ring(_ cx: Double, _ cy: Double) {
    ctx.setStrokeColor(CGColor(colorSpace: cs, components: [1, 1, 1, 0.07])!)
    ctx.setLineWidth(1)
    ctx.strokeEllipse(in: CGRect(x: cx-68, y: cy-68, width: 136, height: 136))
}
ring(165, 220)
ring(495, 220)

// ── Arrow (shaft + head) ──────────────────────────────────────────────────────

let arrowColor = CGColor(colorSpace: cs, components: [1, 1, 1, 0.20])!
ctx.setFillColor(arrowColor)

// Shaft rect
let shaft = CGRect(x: 262, y: 218, width: 118, height: 4)
ctx.fill(shaft)

// Arrowhead triangle
let tip = CGPoint(x: 398, y: 220)
let head = CGMutablePath()
head.move(to: tip)
head.addLine(to: CGPoint(x: 384, y: 231))
head.addLine(to: CGPoint(x: 384, y: 209))
head.closeSubpath()
ctx.addPath(head)
ctx.fillPath()

// ── Text helper ───────────────────────────────────────────────────────────────

func drawText(_ text: String, x: Double, y: Double, width: Double,
              size: Double, weight: String = "Regular",
              alpha: Double, centered: Bool = true) {
    let fontName = "SF Pro Display-\(weight)" as CFString
    var font = CTFontCreateWithName(fontName, size, nil)
    // Fallback to system font if SF Pro isn't available
    if CTFontGetSize(font) == 0 || CTFontCopyPostScriptName(font) as String == ".LastResort" {
        font = CTFontCreateWithName("HelveticaNeue" as CFString, size, nil)
    }

    let color = CGColor(colorSpace: cs, components: [1, 1, 1, alpha])!
    var align: CTTextAlignment = centered ? .center : .left
    let paraSettings = [
        CTParagraphStyleSetting(spec: .alignment, valueSize: MemoryLayout<CTTextAlignment>.size, value: &align)
    ]
    let paraStyle = CTParagraphStyleCreate(paraSettings, paraSettings.count)

    let attrs: [CFString: Any] = [
        kCTFontAttributeName: font,
        kCTForegroundColorAttributeName: color,
        kCTParagraphStyleAttributeName: paraStyle,
    ]
    let attrStr = CFAttributedStringCreate(nil, text as CFString, attrs as CFDictionary)!
    let framesetter = CTFramesetterCreateWithAttributedString(attrStr)
    let path = CGPath(rect: CGRect(x: x, y: y, width: width, height: size * 1.4), transform: nil)
    let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil)
    CTFrameDraw(frame, ctx)
}

// ── "NotchSpace" wordmark (left icon zone) ────────────────────────────────────

drawText("NotchSpace", x: 65, y: 144, width: 200,
         size: 17, weight: "Semibold", alpha: 0.88)

drawText("Live inside your notch", x: 65, y: 124, width: 200,
         size: 11, weight: "Regular", alpha: 0.32)

// ── "Applications" label (right icon zone) ────────────────────────────────────

drawText("Applications", x: 395, y: 148, width: 200,
         size: 13, weight: "Regular", alpha: 0.40)

// ── Bottom drag instruction ───────────────────────────────────────────────────

drawText("Drag NotchSpace to the Applications folder to install",
         x: 40, y: 28, width: Double(W)-80,
         size: 11, weight: "Regular", alpha: 0.22)

// ── Version badge (bottom-right) ──────────────────────────────────────────────

drawText("v1.0.0", x: Double(W)-90, y: 12, width: 70,
         size: 9.5, weight: "Regular", alpha: 0.18)

// ── Save PNG ──────────────────────────────────────────────────────────────────

guard let cgImage = ctx.makeImage() else { fatalError("makeImage() failed") }

let outURL = URL(fileURLWithPath: "Scripts/dmg-background.png")
guard let dest = CGImageDestinationCreateWithURL(outURL as CFURL, "public.png" as CFString, 1, nil)
else { fatalError("Could not create image destination") }

CGImageDestinationAddImage(dest, cgImage, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("CGImageDestinationFinalize failed") }

print("✓  \(outURL.path)  (\(W)×\(H))")
