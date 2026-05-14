//
//  AquaSaveWidgetLiveActivity.swift
//  AquaSaveWidget
//
//  Created by Foundation 44 on 05/03/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct AquaSaveWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct AquaSaveWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AquaSaveWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension AquaSaveWidgetAttributes {
    fileprivate static var preview: AquaSaveWidgetAttributes {
        AquaSaveWidgetAttributes(name: "World")
    }
}

extension AquaSaveWidgetAttributes.ContentState {
    fileprivate static var smiley: AquaSaveWidgetAttributes.ContentState {
        AquaSaveWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: AquaSaveWidgetAttributes.ContentState {
         AquaSaveWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: AquaSaveWidgetAttributes.preview) {
   AquaSaveWidgetLiveActivity()
} contentStates: {
    AquaSaveWidgetAttributes.ContentState.smiley
    AquaSaveWidgetAttributes.ContentState.starEyes
}
