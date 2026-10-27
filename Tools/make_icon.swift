import AppKit

let S: CGFloat = 1024
let img = NSImage(size: NSSize(width: S, height: S), flipped: false) { _ in
    let ctx = NSGraphicsContext.current!.cgContext
    let bg = NSBezierPath(roundedRect: NSRect(x: 100, y: 100, width: 824, height: 824), xRadius: 190, yRadius: 190)
    ctx.saveGState(); bg.addClip()
    NSGradient(colors: [NSColor(red: 0.10, green: 0.10, blue: 0.16, alpha: 1), NSColor(red: 0.02, green: 0.02, blue: 0.05, alpha: 1)])!
        .draw(in: bg.bounds, angle: -60)
    let glow = NSGradient(colors: [NSColor(red: 0.45, green: 0.2, blue: 1, alpha: 0.55), NSColor(red: 0.45, green: 0.2, blue: 1, alpha: 0)])!
    glow.draw(fromCenter: NSPoint(x: 512, y: 470), radius: 0, toCenter: NSPoint(x: 512, y: 470), radius: 430, options: [])
    ctx.restoreGState()

    let body = NSBezierPath(roundedRect: NSRect(x: 342, y: 232, width: 340, height: 560), xRadius: 170, yRadius: 170)
    NSGradient(colors: [NSColor(white: 0.95, alpha: 1), NSColor(white: 0.62, alpha: 1)])!.draw(in: body, angle: -90)
    NSColor(white: 0.25, alpha: 0.9).setStroke()
    let split = NSBezierPath(); split.lineWidth = 8
    split.move(to: NSPoint(x: 342, y: 580)); split.line(to: NSPoint(x: 682, y: 580)); split.stroke()
    let mid = NSBezierPath(); mid.lineWidth = 8
    mid.move(to: NSPoint(x: 512, y: 580)); mid.line(to: NSPoint(x: 512, y: 792)); mid.stroke()
    let wheel = NSBezierPath(roundedRect: NSRect(x: 489, y: 628, width: 46, height: 100), xRadius: 23, yRadius: 23)
    NSColor(red: 0.30, green: 0.85, blue: 1.0, alpha: 1).setFill(); wheel.fill()
    let strip = NSBezierPath(roundedRect: NSRect(x: 402, y: 300, width: 220, height: 26), xRadius: 13, yRadius: 13)
    NSGradient(colors: [NSColor(red: 1, green: 0.3, blue: 0.5, alpha: 1), NSColor(red: 0.6, green: 0.3, blue: 1, alpha: 1), NSColor(red: 0.2, green: 0.85, blue: 1, alpha: 1)])!.draw(in: strip, angle: 0)
    return true
}
let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
