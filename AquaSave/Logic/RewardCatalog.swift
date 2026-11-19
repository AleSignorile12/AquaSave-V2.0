import SwiftUI

struct Reward: Identifiable {
    enum Group: String, CaseIterable {
        case sensors = "AquaSave sensors"
        case giftCards = "Gift cards"
        case giveBack = "Give back"
    }

    let id: String
    let title: String
    let detail: String
    let cost: Int
    let systemImage: String
    /// nil follows the accent.
    let tint: Color?
    let group: Group

    static let catalog: [Reward] = [
        Reward(id: "sensor15", title: "15% off any sensor", detail: "Add another fixture to your home", cost: 300,
               systemImage: "dot.radiowaves.left.and.right", tint: nil, group: .sensors),
        Reward(id: "sensorfree", title: "Free shower sensor", detail: "Ships in 3–5 days", cost: 3500,
               systemImage: "shower.fill", tint: nil, group: .sensors),
        Reward(id: "spotify1m", title: "Spotify Premium", detail: "1 month", cost: 1000,
               systemImage: "music.note", tint: .green, group: .giftCards),
        Reward(id: "amazon10", title: "Amazon gift card", detail: "€10", cost: 1000,
               systemImage: "shippingbox.fill", tint: .orange, group: .giftCards),
        Reward(id: "amazon25", title: "Amazon gift card", detail: "€25", cost: 2500,
               systemImage: "shippingbox.fill", tint: .orange, group: .giftCards),
        Reward(id: "cleanwater", title: "Fund clean water", detail: "1,000 L for a family in need", cost: 300,
               systemImage: "hands.and.sparkles.fill", tint: .pink, group: .giveBack),
    ]

    /// Demo voucher code. Real codes would come from the partner's API.
    static func makeCode() -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        let block = { String((0..<4).map { _ in chars.randomElement()! }) }
        return "AQS-\(block())-\(block())"
    }
}
