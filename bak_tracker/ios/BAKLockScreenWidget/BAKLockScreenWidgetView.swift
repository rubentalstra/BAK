//
//  BAKLockScreenWidgetView.swift
//  BAKLockScreenWidget
//
//  Created by Ruben Daniël Talstra on 06/10/2024.
//

import SwiftUI
import WidgetKit

struct BAKLockScreenWidgetView: View {
    var entry: SimpleEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryInline:
            Label {
                Text("Debt \(entry.debt) | Drank \(entry.chucked)")
            } icon: {
                Image(systemName: "mug")
                    .foregroundColor(.orange)
            }
            .accessibilityLabel("You have a debt of \(entry.debt) beers, and have drunk \(entry.chucked) beers")

        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 2) {
                    Image(systemName: "mug")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text(entry.debt)
                        .font(.headline)
                        .foregroundColor(.orange)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("BAK debt is \(entry.debt) beers")

        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.associationName)
                    .font(.caption2)
                    .lineLimit(1)
                    .fontWeight(.bold)
                    .minimumScaleFactor(0.5)
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "mug")
                            .foregroundColor(.orange)
                        Text(entry.debt)
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal")
                            .foregroundColor(.green)
                        Text(entry.chucked)
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding(.vertical, 2)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(entry.associationName). BAK debt is \(entry.debt) beers. Chucked drinks are \(entry.chucked) beers")

        default:
            EmptyView()
        }
    }
}
