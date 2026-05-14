//
//  WaterUsage.swift
//  AcquaSave
//
//  Created by Foundation 44 on 05/03/26.
//

import Foundation
import SwiftData

struct WaterUsage: Identifiable, Codable {
    
    let id: UUID
    let date: Date
    let liters: Double
    
    init(date: Date, liters: Double) {
        self.id = UUID()
        self.date = date
        self.liters = liters
    }
}
