//
//  LockScreenWidget.swift
//  widget
//
//  Created by Ruben Daniël Talstra on 06/10/2024.
//

import WidgetKit
import SwiftUI

struct LockScreenWidget: Widget {
    let kind: String = "LockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            LockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("BAK Lock Screen")
        .description("View BAK and Chucked data on your lock screen.")
        .supportedFamilies([.accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}
