//
//  HydrationAnalytics.swift
//  AcquaSave
//
//  Created by Foundation 44 on 06/03/26.
//

import Foundation

enum HydrationAnalytics {
    static func sumML(on day: Date, records: [HydrationRecord], calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: day)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return records
            .filter { $0.timestamp >= start && $0.timestamp < end }
            .reduce(0) { $0 + $1.ml }
    }

    static func lastDrink(on day: Date, records: [HydrationRecord], calendar: Calendar = .current) -> Date? {
        let start = calendar.startOfDay(for: day)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return records
            .filter { $0.timestamp >= start && $0.timestamp < end }
            .max(by: { $0.timestamp < $1.timestamp })?
            .timestamp
    }
}
