//
//  AquaSaveWidgetBundle.swift
//  AquaSaveWidget
//
//  Created by Foundation 44 on 05/03/26.
//

import WidgetKit
import SwiftUI

struct AquaSaveWidgetBundle: WidgetBundle {
    var body: some Widget {
        AquaSaveWidget()
        AquaSaveWidgetControl()
        AquaSaveWidgetLiveActivity()
    }
}
