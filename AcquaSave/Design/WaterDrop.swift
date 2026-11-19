import SwiftUI

/// The day's water budget as a drop that drains as you use it.
struct WaterDrop: View {
    /// 0 = budget spent, 1 = full budget left.
    let level: Double
    let tint: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { context in
            let phase = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate * 1.6
            ZStack {
                DropShape().fill(tint.opacity(0.10))
                Wave(level: level, phase: phase + 2, amplitude: 5)
                    .fill(tint.opacity(0.30))
                Wave(level: level, phase: phase, amplitude: 6)
                    .fill(LinearGradient(colors: [tint.opacity(0.75), tint], startPoint: .top, endPoint: .bottom))
            }
            .clipShape(DropShape())
            .overlay(DropShape().stroke(tint.opacity(0.35), lineWidth: 1.5))
        }
        .accessibilityElement()
        .accessibilityLabel("Water budget")
        .accessibilityValue("\(Int((level * 100).rounded())) percent left")
    }
}

struct DropShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        let r = w / 2
        let cy = h - r
        var p = Path()
        p.move(to: CGPoint(x: w / 2, y: 0))
        p.addCurve(to: CGPoint(x: w, y: cy),
                   control1: CGPoint(x: w / 2 + r * 0.2, y: h * 0.16),
                   control2: CGPoint(x: w, y: cy - r * 0.75))
        p.addArc(center: CGPoint(x: w / 2, y: cy), radius: r,
                 startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
        p.addCurve(to: CGPoint(x: w / 2, y: 0),
                   control1: CGPoint(x: 0, y: cy - r * 0.75),
                   control2: CGPoint(x: w / 2 - r * 0.2, y: h * 0.16))
        p.closeSubpath()
        return p.offsetBy(dx: rect.minX, dy: rect.minY)
    }
}

struct Wave: Shape {
    var level: Double
    var phase: Double
    var amplitude: Double

    var animatableData: Double {
        get { level }
        set { level = newValue }
    }

    func path(in rect: CGRect) -> Path {
        // Flatten the wave near empty and full so it never pokes past the drop.
        let amp = amplitude * min(1, min(level, 1 - level) * 6)
        let surface = rect.maxY - rect.height * level
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        for x in stride(from: rect.minX, through: rect.maxX, by: 2) {
            let t = (x - rect.minX) / rect.width
            p.addLine(to: CGPoint(x: x, y: surface + sin(t * .pi * 2.4 + phase) * amp))
        }
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

#Preview {
    HStack(spacing: 24) {
        WaterDrop(level: 0.8, tint: .green)
        WaterDrop(level: 0.2, tint: .orange)
        WaterDrop(level: 0, tint: .red)
    }
    .frame(height: 150)
    .padding()
}
