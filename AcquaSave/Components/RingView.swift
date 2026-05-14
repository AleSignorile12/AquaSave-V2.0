import SwiftUI

struct RingView: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    let systemImage: String
    let centerValue: Double
    let subtitle: String
    let goal: Double

    private var clamped: Double {
        min(max(progress, 0), 1)
    }

    private var ringGradient: AngularGradient {
        AngularGradient(
            colors: [
                Color.mint,
                Color.green,
                Color.teal,
                Color.mint
            ],
            center: .center
        )
    }

    private var dotPosition: CGPoint {
        let radius = size / 2
        let angle = Angle.degrees((clamped * 360) - 90)
        let x = radius + cos(angle.radians) * (radius - lineWidth / 2)
        let y = radius + sin(angle.radians) * (radius - lineWidth / 2)
        return CGPoint(x: x, y: y)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.green.opacity(0.14), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    ringGradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: .green.opacity(0.16), radius: 10, x: 0, y: 4)
                .animation(.spring(response: 0.6, dampingFraction: 0.86), value: clamped)

            if clamped > 0.02 {
                Circle()
                    .fill(.white)
                    .frame(width: lineWidth * 0.72, height: lineWidth * 0.72)
                    .shadow(color: .green.opacity(0.26), radius: 8, x: 0, y: 0)
                    .position(dotPosition)
                    .animation(.spring(response: 0.6, dampingFraction: 0.86), value: clamped)
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.green.opacity(0.10),
                            .clear
                        ],
                        center: .center,
                        startRadius: 4,
                        endRadius: size * 0.34
                    )
                )
                .frame(width: size * 0.68, height: size * 0.68)

            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.mint, .green],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("\(Int(centerValue)) L")
                    .font(.system(size: 22, weight: .bold))
                    .monospacedDigit()

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Water usage ring")
        .accessibilityValue("\(Int(centerValue)) liters out of \(Int(goal))")
    }
}
