import SwiftUI

struct BottleHydrationChartFitness: View {
    let progress: Double
    let currentML: Int
    let goalML: Int
    var subtitle: String = "Today"

    @State private var animatedProgress: Double = 0
    @State private var wavePhase: CGFloat = 0

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // Outer shell
                BottleBodyShape()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        BottleBodyShape()
                            .stroke(.white.opacity(0.30), lineWidth: 1.2)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 10, y: 6)

                // Water fill
                GeometryReader { geo in
                    let size = geo.size
                    let clamped = min(max(animatedProgress, 0), 1)
                    let waterHeight = size.height * clamped
                    let waterTopY = size.height - waterHeight

                    ZStack(alignment: .top) {
                        // main water
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.cyan.opacity(0.55),
                                        Color.blue.opacity(0.42)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        // surface wave
                        WaterSurfaceShape(phase: wavePhase, amplitude: 4)
                            .fill(Color.white.opacity(0.16))
                            .frame(height: 14)
                            .offset(y: -6)
                    }
                    .frame(width: size.width, height: waterHeight, alignment: .top)
                    .position(x: size.width / 2, y: waterTopY + waterHeight / 2)
                    .mask(
                        BottleInnerShape()
                            .padding(10)
                    )
                }
                .allowsHitTesting(false)

                // soft gloss
                BottleBodyShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.26),
                                .white.opacity(0.08),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .mask(
                        BottleBodyShape().inset(by: 4)
                    )
                    .allowsHitTesting(false)

                // left highlight strip
                BottleBodyShape()
                    .fill(.white.opacity(0.12))
                    .mask(
                        Capsule()
                            .frame(width: 14)
                            .offset(x: -26, y: 8)
                    )
                    .allowsHitTesting(false)

                VStack(spacing: 4) {
                    Text("\(currentML) ml")
                        .font(.system(size: 21, weight: .bold))
                        .monospacedDigit()

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Goal \(goalML) ml")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 118, height: 220)
            .onAppear {
                withAnimation(.spring(response: 0.65, dampingFraction: 0.86)) {
                    animatedProgress = min(max(progress, 0), 1)
                }

                withAnimation(.linear(duration: 1.7).repeatForever(autoreverses: false)) {
                    wavePhase = 1
                }
            }
            .onChange(of: progress) { _, newValue in
                withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                    animatedProgress = min(max(newValue, 0), 1)
                }
            }

            ProgressView(value: animatedProgress)
                .frame(width: 150)
        }
    }
}

// MARK: - Shapes

private struct BottleBodyShape: InsettableShape {
    var insetAmount: CGFloat = 0

    func inset(by amount: CGFloat) -> some InsettableShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: insetAmount, dy: insetAmount)

        let w = r.width
        let h = r.height

        let neckWidth = w * 0.42
        let neckHeight = h * 0.10
        let shoulderDrop = h * 0.11
        let sideInset: CGFloat = 8
        let bottomRadius: CGFloat = 18

        let neckLeft = r.midX - neckWidth / 2
        let neckRight = r.midX + neckWidth / 2
        let neckBottom = r.minY + neckHeight

        var p = Path()

        // Start from top-left neck
        p.move(to: CGPoint(x: neckLeft, y: r.minY + 4))

        // top curve (no separate cap)
        p.addQuadCurve(
            to: CGPoint(x: neckRight, y: r.minY + 4),
            control: CGPoint(x: r.midX, y: r.minY - 4)
        )

        // right neck down
        p.addLine(to: CGPoint(x: neckRight, y: neckBottom))

        // right shoulder
        p.addCurve(
            to: CGPoint(x: r.maxX - sideInset, y: neckBottom + shoulderDrop),
            control1: CGPoint(x: neckRight + 16, y: neckBottom + 4),
            control2: CGPoint(x: r.maxX - sideInset, y: neckBottom + 18)
        )

        // right side
        p.addLine(to: CGPoint(x: r.maxX - sideInset, y: r.maxY - bottomRadius))

        // bottom right
        p.addQuadCurve(
            to: CGPoint(x: r.maxX - sideInset - bottomRadius, y: r.maxY),
            control: CGPoint(x: r.maxX - sideInset, y: r.maxY)
        )

        // bottom
        p.addLine(to: CGPoint(x: r.minX + sideInset + bottomRadius, y: r.maxY))

        // bottom left
        p.addQuadCurve(
            to: CGPoint(x: r.minX + sideInset, y: r.maxY - bottomRadius),
            control: CGPoint(x: r.minX + sideInset, y: r.maxY)
        )

        // left side
        p.addLine(to: CGPoint(x: r.minX + sideInset, y: neckBottom + shoulderDrop))

        // left shoulder
        p.addCurve(
            to: CGPoint(x: neckLeft, y: neckBottom),
            control1: CGPoint(x: r.minX + sideInset, y: neckBottom + 18),
            control2: CGPoint(x: neckLeft - 16, y: neckBottom + 4)
        )

        p.closeSubpath()
        return p
    }
}

private struct BottleInnerShape: Shape {
    func path(in rect: CGRect) -> Path {
        BottleBodyShape()
            .inset(by: 0)
            .path(in: rect)
    }
}

private struct WaterSurfaceShape: Shape {
    var phase: CGFloat
    var amplitude: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY

        path.move(to: CGPoint(x: 0, y: midY))

        let step: CGFloat = 4
        var x: CGFloat = 0
        while x <= rect.width {
            let relative = x / rect.width
            let y = midY + sin((relative + phase) * .pi * 2) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
            x += step
        }

        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}
