//
//  WaterDefaultsMigration.swift
//  AcquaSave
//
//  Created by Foundation 44 on 05/03/26.
//

import Foundation
import SwiftData

enum WaterDefaultsMigration {

    private static let migratedKey = "did_migrate_water_usage_to_swiftdata"
    private static let legacyKey = "water_usage_data" // quello che usavamo in UserDefaults

    struct LegacyWaterUsage: Codable {
        let id: UUID
        let date: Date
        let liters: Double
    }

    static func migrateIfNeeded(container: ModelContainer) async {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: migratedKey) { return }

        guard let data = defaults.data(forKey: legacyKey),
              let decoded = try? JSONDecoder().decode([LegacyWaterUsage].self, from: data),
              !decoded.isEmpty else {
            defaults.set(true, forKey: migratedKey)
            return
        }

        let context = ModelContext(container)
        for item in decoded {
            // legacy aveva `date`, lo mappiamo su timestamp
            let rec = WaterUsageRecord(timestamp: item.date, liters: item.liters, deviceName: nil)
            context.insert(rec)
        }

        do {
            try context.save()
            defaults.set(true, forKey: migratedKey)
        } catch {
            // se fallisce, non “bruciamo” la migrazione
        }
    }
}
