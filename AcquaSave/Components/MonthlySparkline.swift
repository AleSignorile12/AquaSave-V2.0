import SwiftUI

struct MonthlySparkline: View {
    let data: [(day: Date, liters: Double)]

    private var maxLiters: Double {
        max(data.map(\.liters).max() ?? 1, 1)
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            Path { path in
                for i in data.indices {
                    let x = w * CGFloat(i) / CGFloat(max(data.count - 1, 1))
                    let y = h - (h * CGFloat(data[i].liters / maxLiters))
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(.green, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.green.opacity(0.06))
            )
        }
    }
}
