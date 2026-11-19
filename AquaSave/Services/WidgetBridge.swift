//
//  WidgetBridge.swift
//  AquaSave
//
//  Created by Foundation 44 on 05/03/26.
//

import Foundation
import WidgetKit

enum WidgetBridge {
    static let appGroupID = "group.com.alessandrosignorile.AquaSave" // 👈 cambia con il tuo
    static let keyTodayLiters = "widget_today_liters"
    static let keyDailyGoal = "widget_daily_goal"
    static let keyPoints = "widget_points"
    static let keyStreak = "widget_streak"
    static let keyLastUpdated = "widget_last_updated"

    static func save(todayLiters: Double, dailyGoal: Double, points: Int, streak: Int) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        defaults.set(todayLiters, forKey: keyTodayLiters)
        defaults.set(dailyGoal, forKey: keyDailyGoal)
        defaults.set(points, forKey: keyPoints)
        defaults.set(streak, forKey: keyStreak)
        defaults.set(Date().timeIntervalSince1970, forKey: keyLastUpdated)

        // ping widget refresh
        WidgetCenter.shared.reloadTimelines(ofKind: "AquaSaveWidget")
    }
}
