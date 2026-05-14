//
//  UsageViewModel.swift
//  AcquaSave
//
//  Created by Foundation 44 on 05/03/26.
//

import Foundation
import Combine

class UsageViewModel: ObservableObject {
    
    @Published var usages: [WaterUsage] = []
    
    @Published var todayUsage: Double = 0
    @Published var dailyGoal: Double = 120
    @Published var points: Int = 0
    
    private let service = WaterDataService()
    
    init() {
        loadData()
        calculateTodayUsage()
    }
    
    func addUsage(liters: Double) {
        
        let newUsage = WaterUsage(date: Date(), liters: liters)
        usages.append(newUsage)
        
        service.save(usages: usages)
        
        calculateTodayUsage()
    }
    
    func calculateTodayUsage() {
        
        let today = Calendar.current.startOfDay(for: Date())
        
        todayUsage = usages
            .filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
            .map { $0.liters }
            .reduce(0, +)
        
        calculatePoints()
    }
    
    func calculatePoints() {
        
        if todayUsage < dailyGoal {
            points = Int((dailyGoal - todayUsage) * 2)
        } else {
            points = 0
        }
    }
    
    func loadData() {
        usages = service.load()
    }
}
