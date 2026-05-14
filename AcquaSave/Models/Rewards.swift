//
//  Rewards.swift
//  AcquaSave
//
//  Created by Foundation 44 on 05/03/26.
//

import Foundation
import SwiftData

struct Reward: Identifiable {
    
    let id = UUID()
    let name: String
    let points: Int
    
}
