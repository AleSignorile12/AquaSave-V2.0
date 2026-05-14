//
//  HydrationRecord.swift
//  AcquaSave
//
//  Created by Foundation 44 on 06/03/26.
//

import Foundation
import SwiftData

@Model
final class HydrationRecord {
    var timestamp: Date
    var ml: Int

    init(timestamp: Date = .now, ml: Int) {
        self.timestamp = timestamp
        self.ml = ml
    }
}
