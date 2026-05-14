//
//  WaterDataServices.swift
//  AcquaSave
//
//  Created by Foundation 44 on 05/03/26.
//

import Foundation

class WaterDataService {
    
    private let key = "water_usage_data"
    
    func save(usages: [WaterUsage]) {
        
        if let encoded = try? JSONEncoder().encode(usages) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    func load() -> [WaterUsage] {
        
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([WaterUsage].self, from: data)
        else {
            return []
        }
        
        return decoded
    }
}
