import AppKit
import ImageIO
import UniformTypeIdentifiers

// A small native vector mark, rendered into the app's opaque 1024px icon.
let output = CommandLine.arguments.dropFirst().first ?? "Fasting/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
guard let context = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8,
    bytesPerRow: 4096, space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { fatalError("Could not create bitmap") }
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
let rect = NSRect(x: 0, y: 0, width: 1024, height: 1024)
NSGradient(starting: NSColor(red: 0.89, green: 0.97, blue: 0.91, alpha: 1), ending: NSColor(red: 0.49, green: 0.78, blue: 0.69, alpha: 1))!.draw(in: rect, angle: -45)
let ring = NSBezierPath(ovalIn: NSRect(x: 154, y: 154, width: 716, height: 716))
NSColor.white.withAlphaComponent(0.55).setStroke()
ring.lineWidth = 12
ring.stroke()
let innerRing = NSBezierPath(ovalIn: NSRect(x: 181, y: 181, width: 662, height: 662))
NSColor.white.withAlphaComponent(0.17).setStroke()
innerRing.lineWidth = 4
innerRing.stroke()
let glass = NSBezierPath()
glass.move(to: NSPoint(x: 363, y: 708))
glass.curve(to: NSPoint(x: 455, y: 539), controlPoint1: NSPoint(x: 363, y: 624), controlPoint2: NSPoint(x: 397, y: 583))
glass.curve(to: NSPoint(x: 455, y: 485), controlPoint1: NSPoint(x: 482, y: 519), controlPoint2: NSPoint(x: 482, y: 505))
glass.curve(to: NSPoint(x: 363, y: 316), controlPoint1: NSPoint(x: 397, y: 441), controlPoint2: NSPoint(x: 363, y: 400))
glass.line(to: NSPoint(x: 661, y: 316))
glass.curve(to: NSPoint(x: 569, y: 485), controlPoint1: NSPoint(x: 661, y: 400), controlPoint2: NSPoint(x: 627, y: 441))
glass.curve(to: NSPoint(x: 569, y: 539), controlPoint1: NSPoint(x: 542, y: 505), controlPoint2: NSPoint(x: 542, y: 519))
glass.curve(to: NSPoint(x: 661, y: 708), controlPoint1: NSPoint(x: 627, y: 583), controlPoint2: NSPoint(x: 661, y: 624))
glass.close()
NSColor.white.withAlphaComponent(0.32).setFill()
glass.fill()
let teal = NSColor(red: 0.10, green: 0.37, blue: 0.31, alpha: 1)
teal.setStroke()
glass.lineWidth = 19
glass.lineJoinStyle = .round
glass.stroke()
for y in [316.0, 708.0] {
    let cap = NSBezierPath()
    cap.move(to: NSPoint(x: 340, y: y))
    cap.line(to: NSPoint(x: 684, y: y))
    cap.lineWidth = 24
    cap.lineCapStyle = .round
    cap.stroke()
}
let sand = NSBezierPath()
sand.move(to: NSPoint(x: 413, y: 348))
sand.line(to: NSPoint(x: 611, y: 348))
sand.curve(to: NSPoint(x: 512, y: 438), controlPoint1: NSPoint(x: 597, y: 390), controlPoint2: NSPoint(x: 549, y: 418))
sand.curve(to: NSPoint(x: 413, y: 348), controlPoint1: NSPoint(x: 475, y: 418), controlPoint2: NSPoint(x: 427, y: 390))
sand.close()
teal.withAlphaComponent(0.8).setFill()
sand.fill()
NSGraphicsContext.restoreGraphicsState()
guard let rendered = context.makeImage(),
    let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: output) as CFURL,
        UTType.png.identifier as CFString, 1, nil) else { fatalError("Could not render icon") }
CGImageDestinationAddImage(destination, rendered, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("Could not save icon") }
print("Rendered \(output)")
