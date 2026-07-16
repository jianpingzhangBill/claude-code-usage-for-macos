import AppKit
import CoreGraphics

// Renders the app icon (a speedometer-style gauge on a warm coral squircle)
// to a 1024x1024 PNG. Run:  swift icon/make_icon.swift  [outPath]

let S = 1024
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon/icon_1024.png"

let cs = CGColorSpace(name: CGColorSpace.sRGB)!
guard let ctx = CGContext(data: nil, width: S, height: S, bitsPerComponent: 8,
                          bytesPerRow: 0, space: cs,
                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
    fatalError("no ctx")
}

let s = CGFloat(S)
func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: cs, components: [r/255, g/255, b/255, a])!
}
func deg(_ d: CGFloat) -> CGFloat { d * .pi / 180 }

// MARK: Squircle background with warm gradient
let inset: CGFloat = s * 0.075
let rect = CGRect(x: inset, y: inset, width: s - 2*inset, height: s - 2*inset)
let radius = rect.width * 0.2237
let squircle = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)

ctx.saveGState()
ctx.addPath(squircle)
ctx.clip()
let grad = CGGradient(colorsSpace: cs,
                      colors: [rgb(240, 165, 130), rgb(217, 119, 87), rgb(183, 82, 48)] as CFArray,
                      locations: [0.0, 0.55, 1.0])!
// diagonal top-left -> bottom-right
ctx.drawLinearGradient(grad,
                       start: CGPoint(x: rect.minX, y: rect.maxY),
                       end: CGPoint(x: rect.maxX, y: rect.minY),
                       options: [])
// soft top highlight
let hl = CGGradient(colorsSpace: cs,
                    colors: [rgb(255, 255, 255, 0.22), rgb(255, 255, 255, 0.0)] as CFArray,
                    locations: [0.0, 1.0])!
ctx.drawLinearGradient(hl,
                       start: CGPoint(x: rect.midX, y: rect.maxY),
                       end: CGPoint(x: rect.midX, y: rect.midY),
                       options: [])
ctx.restoreGState()

// subtle inner rim
ctx.saveGState()
ctx.addPath(squircle)
ctx.setStrokeColor(rgb(255, 255, 255, 0.18))
ctx.setLineWidth(s * 0.006)
ctx.strokePath()
ctx.restoreGState()

// MARK: Gauge geometry
let center = CGPoint(x: s/2, y: s*0.475)
let r = rect.width * 0.315
let start: CGFloat = 225   // lower-left  (value 0)
let sweep: CGFloat = 270   // clockwise to lower-right (value 1)
let value: CGFloat = 0.67
func angle(_ f: CGFloat) -> CGFloat { start - f * sweep } // clockwise (y-up)

// track
ctx.saveGState()
ctx.setLineCap(.round)
ctx.setLineWidth(s * 0.072)
ctx.setStrokeColor(rgb(255, 255, 255, 0.28))
let track = CGMutablePath()
track.addArc(center: center, radius: r, startAngle: deg(start),
             endAngle: deg(start - sweep), clockwise: true)
ctx.addPath(track)
ctx.strokePath()
ctx.restoreGState()

// progress arc with glow
ctx.saveGState()
ctx.setLineCap(.round)
ctx.setLineWidth(s * 0.072)
ctx.setShadow(offset: .zero, blur: s * 0.03, color: rgb(255, 250, 245, 0.9))
ctx.setStrokeColor(rgb(255, 252, 248, 0.98))
let prog = CGMutablePath()
prog.addArc(center: center, radius: r, startAngle: deg(start),
            endAngle: deg(angle(value)), clockwise: true)
ctx.addPath(prog)
ctx.strokePath()
ctx.restoreGState()

// tick marks
ctx.saveGState()
ctx.setLineCap(.round)
ctx.setStrokeColor(rgb(255, 255, 255, 0.45))
let tickInner = r - s*0.055
let tickOuter = r - s*0.02
for i in 0...10 {
    let f = CGFloat(i)/10
    let a = deg(angle(f))
    let major = i % 5 == 0
    ctx.setLineWidth(major ? s*0.012 : s*0.006)
    let p1 = CGPoint(x: center.x + cos(a)*tickInner, y: center.y + sin(a)*tickInner)
    let p2 = CGPoint(x: center.x + cos(a)*(major ? tickOuter + s*0.008 : tickOuter),
                     y: center.y + sin(a)*(major ? tickOuter + s*0.008 : tickOuter))
    ctx.move(to: p1); ctx.addLine(to: p2); ctx.strokePath()
}
ctx.restoreGState()

// needle (tapered)
let na = deg(angle(value))
let needleLen = r + s*0.01
let baseW = s * 0.028
let tip = CGPoint(x: center.x + cos(na)*needleLen, y: center.y + sin(na)*needleLen)
let perp = na + .pi/2
let b1 = CGPoint(x: center.x + cos(perp)*baseW, y: center.y + sin(perp)*baseW)
let b2 = CGPoint(x: center.x - cos(perp)*baseW, y: center.y - sin(perp)*baseW)
// tail
let tail = CGPoint(x: center.x - cos(na)*s*0.05, y: center.y - sin(na)*s*0.05)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -s*0.004), blur: s*0.02, color: rgb(120, 45, 20, 0.35))
ctx.setFillColor(rgb(255, 252, 248))
let needle = CGMutablePath()
needle.move(to: tip)
needle.addLine(to: b1)
needle.addLine(to: tail)
needle.addLine(to: b2)
needle.closeSubpath()
ctx.addPath(needle)
ctx.fillPath()
ctx.restoreGState()

// hub
ctx.setFillColor(rgb(255, 252, 248))
ctx.fillEllipse(in: CGRect(x: center.x - s*0.055, y: center.y - s*0.055, width: s*0.11, height: s*0.11))
ctx.setFillColor(rgb(200, 92, 55))
ctx.fillEllipse(in: CGRect(x: center.x - s*0.024, y: center.y - s*0.024, width: s*0.048, height: s*0.048))

// MARK: write PNG
guard let img = ctx.makeImage() else { fatalError("no image") }
let rep = NSBitmapImageRep(cgImage: img)
guard let data = rep.representation(using: .png, properties: [:]) else { fatalError("no png") }
try! data.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
