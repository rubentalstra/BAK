//
//  HomeWidget.swift
//  widget
//
//  Created by Ruben Daniël Talstra on 04/10/2024.
//

import WidgetKit
import SwiftUI

struct HomeWidget: Widget {
    let kind: String = "BAKWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            HomeWidgetView(entry: entry)
        }
        .configurationDisplayName("BAK")
        .description("Track your chucked drinks and drink debt within your association.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
