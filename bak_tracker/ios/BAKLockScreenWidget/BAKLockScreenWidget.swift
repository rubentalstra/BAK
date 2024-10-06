//
//  BAKLockScreenWidget.swift
//  BAKLockScreenWidget
//
//  Created by Ruben Daniël Talstra on 06/10/2024.
//

import WidgetKit
import SwiftUI

struct BAKLockScreenWidget: Widget {
    let kind: String = "BAKLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            BAKLockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("BAK Lock Screen")
        .description("View BAK and Chucked data on your lock screen.")
        .supportedFamilies([.accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}
