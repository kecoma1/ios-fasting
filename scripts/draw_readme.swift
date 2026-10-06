import AppKit
import ImageIO
import UniformTypeIdentifiers

// Native composition of actual screenshots; no generated or redrawn app UI.
// Three aligned iPhones match ios-clipboard's README composition.
let assets = URL(fileURLWithPath: "docs/assets", isDirectory: true)

func load(_ path: String) -> NSImage {
    guard let image = NSImage(contentsOfFile: path) else { fatalError("Missing image: \(path)") }
    return image
}

func render(width: Int, height: Int, to output: URL, draw: () -> Void) {
    guard let context = CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { fatalError("Could not create bitmap") }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
    NSGraphicsContext.current?.imageInterpolation = .high
    draw()
    NSGraphicsContext.restoreGraphicsState()
    guard let image = context.makeImage(),
          let destination = CGImageDestinationCreateWithURL(
            output as CFURL, UTType.png.identifier as CFString, 1, nil
          ) else { fatalError("Could not create PNG") }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { fatalError("Could not save PNG") }
}

let icon = load("Fasting/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
render(width: 512, height: 512, to: assets.appendingPathComponent("fasting-icon.png")) {
    NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: 512, height: 512), xRadius: 114, yRadius: 114).addClip()
    icon.draw(in: NSRect(x: 0, y: 0, width: 512, height: 512))
}

let canvasHeight: CGFloat = 1125
func phone(_ filename: String, x: CGFloat, top: CGFloat, width: CGFloat) {
    let image = load(assets.appendingPathComponent(filename).path)
    let inset: CGFloat = 14
    let screenWidth = width - inset * 2
    let screenHeight = screenWidth * image.size.height / image.size.width
    let height = screenHeight + inset * 2
    let frame = NSRect(x: x, y: canvasHeight - top - height, width: width, height: height)
    let outline = NSBezierPath(roundedRect: frame, xRadius: width * 0.165, yRadius: width * 0.165)
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.18)
    shadow.shadowBlurRadius = 28
    shadow.shadowOffset = NSSize(width: 0, height: -12)
    shadow.set()
    NSColor(calibratedWhite: 0.13, alpha: 1).setFill()
    outline.fill()
    NSGraphicsContext.restoreGraphicsState()
    NSColor(calibratedWhite: 0.48, alpha: 1).setStroke()
    outline.lineWidth = 2
    outline.stroke()
    let bezel = NSBezierPath(roundedRect: frame.insetBy(dx: 4, dy: 4), xRadius: width * 0.155, yRadius: width * 0.155)
    NSColor(calibratedWhite: 0.06, alpha: 1).setFill()
    bezel.fill()
    NSGraphicsContext.saveGraphicsState()
    let screen = frame.insetBy(dx: inset, dy: inset)
    NSBezierPath(roundedRect: screen, xRadius: width * 0.135, yRadius: width * 0.135).addClip()
    image.draw(in: screen)
    // XCTest screenshots omit the display cutout; draw it as part of the device hardware.
    let island = NSRect(x: screen.midX - screen.width * 0.15,
                        y: screen.maxY - screen.width * 0.116,
                        width: screen.width * 0.30, height: screen.width * 0.083)
    NSColor.black.setFill()
    NSBezierPath(roundedRect: island, xRadius: island.height / 2, yRadius: island.height / 2).fill()
    NSGraphicsContext.restoreGraphicsState()
}

render(width: 1800, height: 1125, to: assets.appendingPathComponent("fasting-hero-en.png")) {
    NSGradient(
        starting: NSColor(red: 0.62, green: 0.90, blue: 0.80, alpha: 1),
        ending: NSColor(red: 0.10, green: 0.48, blue: 0.40, alpha: 1)
    )!.draw(in: NSRect(x: 0, y: 0, width: 1800, height: canvasHeight), angle: -35)
    phone("fasting-history-en.png", x: 202, top: 159, width: 436)
    phone("fasting-dark-en.png", x: 1162, top: 159, width: 436)
    phone("fasting-timer-en.png", x: 656, top: 55, width: 488)
}
print("Rendered the Fasting icon and three-device README cover.")
