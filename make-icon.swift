#!/usr/bin/env swift
// Рисует иконку приложения (1024×1024 PNG) средствами AppKit.
import AppKit

let size = 1024.0
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

let rect = NSRect(x: 0, y: 0, width: size, height: size)

// Фон: скруглённый прямоугольник с градиентом (фиолетовый → синий).
let radius = size * 0.22
let bg = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
bg.addClip()
let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.42, green: 0.27, blue: 0.86, alpha: 1),
    NSColor(calibratedRed: 0.20, green: 0.51, blue: 0.96, alpha: 1)
])!
gradient.draw(in: rect, angle: -90)

// Символ merge по центру (белый).
let config = NSImage.SymbolConfiguration(pointSize: size * 0.5, weight: .semibold)
if let symbol = NSImage(systemSymbolName: "arrow.triangle.pull", accessibilityDescription: nil)?
    .withSymbolConfiguration(config) {
    let tinted = NSImage(size: symbol.size)
    tinted.lockFocus()
    NSColor.white.set()
    let r = NSRect(origin: .zero, size: symbol.size)
    symbol.draw(in: r)
    r.fill(using: .sourceAtop)
    tinted.unlockFocus()

    let s = symbol.size
    let target = NSRect(
        x: (size - s.width) / 2,
        y: (size - s.height) / 2,
        width: s.width, height: s.height
    )
    tinted.draw(in: target)
}

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("PNG render failed")
}
let out = URL(fileURLWithPath: "Resources/icon-1024.png")
try! png.write(to: out)
print("✓ \(out.path)")
