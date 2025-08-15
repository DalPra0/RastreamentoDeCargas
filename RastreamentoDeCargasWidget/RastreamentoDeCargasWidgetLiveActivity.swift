//
//  RastreamentoDeCargasWidgetLiveActivity.swift
//  RastreamentoDeCargasWidget
//
//  Created by Lucas Dal Pra Brascher on 15/08/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct RastreamentoDeCargasWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct RastreamentoDeCargasWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RastreamentoDeCargasWidgetAttributes.self) { context in
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

extension RastreamentoDeCargasWidgetAttributes {
    fileprivate static var preview: RastreamentoDeCargasWidgetAttributes {
        RastreamentoDeCargasWidgetAttributes(name: "World")
    }
}

extension RastreamentoDeCargasWidgetAttributes.ContentState {
    fileprivate static var smiley: RastreamentoDeCargasWidgetAttributes.ContentState {
        RastreamentoDeCargasWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: RastreamentoDeCargasWidgetAttributes.ContentState {
         RastreamentoDeCargasWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: RastreamentoDeCargasWidgetAttributes.preview) {
   RastreamentoDeCargasWidgetLiveActivity()
} contentStates: {
    RastreamentoDeCargasWidgetAttributes.ContentState.smiley
    RastreamentoDeCargasWidgetAttributes.ContentState.starEyes
}
