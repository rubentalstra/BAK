//
//  WidgetView.swift
//  Runner
//
//  Created by Ruben Daniël Talstra on 04/10/2024.
//

import SwiftUI
import WidgetKit

struct WidgetEntryView: View {
    var entry: Provider.Entry
    var widgetFamily: WidgetFamily

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading) {
            if widgetFamily == .systemSmall {
                smallWidgetView(entry: entry)
            } else {
                mediumWidgetView(entry: entry)
            }
        }
        .padding()
        .background(Color.clear) // Use system background, no custom background color
    }

    // Small widget view layout
    @ViewBuilder
    private func smallWidgetView(entry: Provider.Entry) -> some View {
        VStack(alignment: .leading) {
            Text(entry.associationName)
                .font(.headline)
                .lineLimit(1)  // Restrict text to one line
                .minimumScaleFactor(0.5)  // Allow text to scale down to fit
                .truncationMode(.tail)  // Truncate with an ellipsis if it overflows
                .foregroundColor(colorScheme == .dark ? AppColors.darkSecondary : AppColors.lightSecondary)
            Spacer()
            HStack {
                VStack {
                    Text("BAK")
                        .font(.caption)
                        .foregroundColor(colorScheme == .dark ? AppColors.darkPrimary : AppColors.lightPrimary)
                    Text(entry.debt)
                        .font(.title)
                        .foregroundColor(colorScheme == .dark ? AppColors.darkRed : AppColors.lightRed)
                }
                Spacer()
                VStack {
                    Text("Chucked")
                        .font(.caption)
                        .foregroundColor(colorScheme == .dark ? AppColors.darkPrimary : AppColors.lightPrimary)
                    Text(entry.chucked)
                        .font(.title)
                        .foregroundColor(colorScheme == .dark ? AppColors.darkGreen : AppColors.lightGreen)
                }
            }
        }
    }

    // Medium widget view layout
    @ViewBuilder
    private func mediumWidgetView(entry: Provider.Entry) -> some View {
        VStack(alignment: .leading) {
            Text(entry.associationName)
                .font(.title2)
                .foregroundColor(colorScheme == .dark ? AppColors.darkSecondary : AppColors.lightSecondary)
            Spacer()
            HStack {
                VStack {
                    Text("BAK")
                        .font(.caption)
                        .foregroundColor(colorScheme == .dark ? AppColors.darkPrimary : AppColors.lightPrimary)
                    Text(entry.debt)
                        .font(.largeTitle)
                        .foregroundColor(colorScheme == .dark ? AppColors.darkRed : AppColors.lightRed)
                }
                Spacer()
                VStack {
                    Text("Chucked Drinks")
                        .font(.caption)
                        .foregroundColor(colorScheme == .dark ? AppColors.darkPrimary : AppColors.lightPrimary)
                    Text(entry.chucked)
                        .font(.largeTitle)
                        .foregroundColor(colorScheme == .dark ? AppColors.darkGreen : AppColors.lightGreen)
                }
            }
        }
    }
}
