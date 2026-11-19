import SwiftUI
import SwiftData

struct SensorProduct: Identifiable {
    let id: String
    let name: String
    let detail: String
    let price: Double
    let systemImage: String
    let tint: Color

    static let catalog: [SensorProduct] = [
        SensorProduct(id: "flow", name: "AquaSave Flow", detail: "Clips under any tap. Spots drips and taps left running.",
                      price: 29, systemImage: DeviceCategory.faucet.systemImage, tint: DeviceCategory.faucet.tint),
        SensorProduct(id: "shower", name: "AquaSave Shower", detail: "Fits between hose and head. Measures warm-up water.",
                      price: 39, systemImage: DeviceCategory.shower.systemImage, tint: DeviceCategory.shower.tint),
        SensorProduct(id: "inline", name: "AquaSave Inline", detail: "For washing machines and dishwashers.",
                      price: 49, systemImage: DeviceCategory.washingMachine.systemImage, tint: DeviceCategory.washingMachine.tint),
        SensorProduct(id: "puck", name: "Leak Puck", detail: "Sits in the cistern and listens for a running toilet.",
                      price: 19, systemImage: DeviceCategory.toilet.systemImage, tint: DeviceCategory.toilet.tint),
        SensorProduct(id: "kit", name: "Home Starter Kit", detail: "Flow, Shower, Inline and Leak Puck. Save €17.",
                      price: 119, systemImage: "shippingbox.fill", tint: .orange),
    ]
}

struct ShopView: View {
    /// The online store, once it exists. Until then products show "Coming soon".
    static let storeURL: URL? = nil

    @Environment(\.theme) private var theme
    @Query(sort: \DayResult.day) private var results: [DayResult]

    var body: some View {
        let tier = TierProgress(results).tier

        ScrollView {
            VStack(spacing: 16) {
                memberCard(tier)

                Card(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(Array(SensorProduct.catalog.enumerated()), id: \.element.id) { index, product in
                            if index > 0 { Divider().padding(.leading, 76) }
                            row(product, discount: tier.hardwareDiscount)
                        }
                    }
                }

                Label("Redeem “15% off any sensor” in Rewards to stack it on top of your tier discount.",
                      systemImage: "gift.fill")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)

                builtInNote
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Sensor Shop")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func memberCard(_ tier: Tier) -> some View {
        Card {
            HStack(spacing: 14) {
                IconCircle(systemImage: tier.systemImage, tint: tier.tint, size: 48)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(tier.name) member")
                        .font(.headline)
                    Text(tier.hardwareDiscount > 0
                         ? "\(Int(tier.hardwareDiscount * 100))% off every sensor, already applied."
                         : "Reach Stream to unlock 5% off every sensor.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func row(_ product: SensorProduct, discount: Double) -> some View {
        let price = product.price * (1 - discount)
        return HStack(alignment: .top, spacing: 14) {
            IconCircle(systemImage: product.systemImage, tint: product.tint, size: 46)
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name).font(.body.weight(.semibold))
                Text(product.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(price, format: .currency(code: "EUR"))
                        .font(.subheadline.weight(.bold))
                        .monospacedDigit()
                    if discount > 0 {
                        Text(product.price, format: .currency(code: "EUR"))
                            .font(.caption)
                            .strikethrough()
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    buyButton
                }
                .padding(.top, 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private var buyButton: some View {
        if let url = Self.storeURL {
            Link("Buy", destination: url)
                .font(.subheadline.weight(.semibold))
                .buttonStyle(.glassProminent)
        } else {
            Text("Coming soon")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.secondary.opacity(0.12), in: .capsule)
        }
    }

    private var builtInNote: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Label("Built-in sensing", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(theme.color)
                Text("AquaSave is built to read appliances that measure their own water. As dishwashers, washing machines and smart taps start reporting flow over open smart-home standards, they'll appear in Devices next to your sensors, no clip-on needed.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    NavigationStack { ShopView() }
}
