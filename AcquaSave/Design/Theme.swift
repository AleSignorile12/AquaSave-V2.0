import SwiftUI

// MARK: - Themes

/// The accent the person picks in Settings. Emerald is the brand.
enum AccentTheme: String, CaseIterable, Identifiable {
    case emerald, ocean, violet, rose

    var id: Self { self }

    var name: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .emerald: Color(light: (0.02, 0.62, 0.36), dark: (0.20, 0.84, 0.52))
        case .ocean: Color(light: (0.00, 0.53, 0.78), dark: (0.29, 0.73, 0.96))
        case .violet: Color(light: (0.42, 0.30, 0.86), dark: (0.64, 0.54, 1.00))
        case .rose: Color(light: (0.84, 0.20, 0.44), dark: (1.00, 0.45, 0.62))
        }
    }

    /// Dark gradient stops for hero surfaces like the wallet card.
    var deep: (Color, Color) {
        switch self {
        case .emerald: (Color(red: 0.02, green: 0.22, blue: 0.14), Color(red: 0.00, green: 0.46, blue: 0.29))
        case .ocean: (Color(red: 0.03, green: 0.19, blue: 0.32), Color(red: 0.00, green: 0.42, blue: 0.62))
        case .violet: (Color(red: 0.14, green: 0.09, blue: 0.34), Color(red: 0.33, green: 0.22, blue: 0.66))
        case .rose: (Color(red: 0.32, green: 0.06, blue: 0.16), Color(red: 0.66, green: 0.16, blue: 0.36))
        }
    }
}

enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: Self { self }
    var name: String { rawValue.capitalized }
    var scheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

extension EnvironmentValues {
    /// Set once at the root from Settings, so every screen and sheet follows the chosen accent.
    @Entry var theme: AccentTheme = .emerald
}

// MARK: - Colors

extension Color {
    /// Credits / rewards accent.
    static let credit = Color(light: (0.84, 0.55, 0.02), dark: (1.00, 0.76, 0.30))
    /// Distinct series colors for charts, assigned by rank. Independent of the accent so charts stay readable.
    static let chartPalette: [Color] = [.teal, .indigo, .orange, .pink, .blue, .yellow, .gray]
    static func chart(_ index: Int) -> Color { chartPalette[index % chartPalette.count] }

    init(light: (Double, Double, Double), dark: (Double, Double, Double)) {
        self.init(uiColor: UIColor { traits in
            let c = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: c.0, green: c.1, blue: c.2, alpha: 1)
        })
    }
}

// MARK: - Credit mark

/// The credits currency sign: a C struck through like €.
struct CreditGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width / 0.86, rect.height)
        let center = CGPoint(x: rect.minX + s * 0.50, y: rect.midY)
        let r = s * 0.38
        var p = Path()
        p.addArc(center: center, radius: r, startAngle: .degrees(48), endAngle: .degrees(312), clockwise: false)
        p.move(to: CGPoint(x: rect.minX + s * 0.02, y: rect.midY))
        p.addLine(to: CGPoint(x: center.x + s * 0.10, y: rect.midY))
        return p
    }
}

struct CreditMark: View {
    var size: CGFloat = 17
    var weight: CGFloat = 0.13

    @ScaledMetric private var scale = 1.0

    var body: some View {
        let s = size * scale
        CreditGlyph()
            .stroke(style: StrokeStyle(lineWidth: max(s * weight, 1.2), lineCap: .round))
            .frame(width: s * 0.86, height: s)
            .accessibilityLabel("credits")
    }
}

/// "₵ 1,250": a credit amount with its sign, sized to sit beside text.
struct CreditAmount: View {
    let value: Int
    var prefix: String = ""
    var size: CGFloat = 15

    var body: some View {
        HStack(spacing: size * 0.22) {
            if !prefix.isEmpty { Text(prefix) }
            CreditMark(size: size * 0.92)
            Text(value, format: .number).monospacedDigit()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(prefix)\(value) credits")
    }
}

// MARK: - Card

struct Card<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 24, style: .continuous))
    }
}

// MARK: - Small building blocks

struct IconCircle: View {
    let systemImage: String
    let tint: Color
    var size: CGFloat = 40

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(tint.opacity(0.14), in: .circle)
    }
}

struct SectionTitle: View {
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.title3.weight(.bold))
            Spacer()
            if let trailing {
                Text(trailing).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(.top, 8)
        .padding(.horizontal, 4)
    }
}

/// Floating label for a chart's touch-and-hold inspection.
struct ChartTooltip: View {
    let title: String
    let lines: [(label: String, value: String, tint: Color)]

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                HStack(spacing: 5) {
                    Circle().fill(line.tint).frame(width: 6, height: 6)
                    Text(line.label).font(.caption)
                    Spacer(minLength: 6)
                    Text(line.value).font(.caption.weight(.semibold)).monospacedDigit()
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(minWidth: 120)
        .background(Color(.systemBackground), in: .rect(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
    }
}

/// Instant press feedback for any tappable surface.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(.rect)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableStyle {
    static var pressable: PressableStyle { .init() }
}

// MARK: - Formatting

extension Double {
    /// "0.8 L", "12 L", "1,240 L"
    var litersText: String {
        formatted(.number.precision(.fractionLength(self < 10 && self > 0 ? 1 : 0))) + " L"
    }
}

extension Sequence {
    func sum(_ value: (Element) -> Double) -> Double { reduce(0) { $0 + value($1) } }
    func sum(_ value: (Element) -> Int) -> Int { reduce(0) { $0 + value($1) } }
}

#Preview {
    HStack(spacing: 16) {
        CreditMark(size: 96).foregroundStyle(Color.credit)
        CreditAmount(value: 1250, size: 28).font(.title.bold())
    }
    .padding()
}
