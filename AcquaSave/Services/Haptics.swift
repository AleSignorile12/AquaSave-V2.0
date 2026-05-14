//
//  Haptics.swift
//  AcquaSave
//
//  Created by Foundation 44 on 05/03/26.
//

import UIKit

enum Haptics {
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
