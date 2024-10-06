//
//  WidgetView.swift
//  Runner
//
//  Created by Ruben Daniël Talstra on 04/10/2024.
//

import SwiftUI
import WidgetKit

struct WidgetView: View {
    var entry: Provider.Entry
    var widgetFamily: WidgetFamily

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading) {
            Text(entry.associationName)
                .font(widgetFamily == .systemSmall ? .headline : .title2)
                .foregroundColor(Color("AccentColor"))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .truncationMode(.tail)
            
            Spacer()
            
            HStack {
                VStack {
                    Text("BAK")
                        .font(.caption)
                        .foregroundColor(Color("CaptionColor"))
                    Text(entry.debt)
                        .font(widgetFamily == .systemSmall ? .title : .largeTitle)
                        .foregroundColor(Color.red)
                }
                Spacer()
                VStack {
                    Text("Chucked")
                        .font(.caption)
                        .foregroundColor(Color("CaptionColor"))
                    Text(entry.chucked)
                        .font(widgetFamily == .systemSmall ? .title : .largeTitle)
                        .foregroundColor(Color.green)
                }
            }
        }
        .padding()
        .background(Color("WidgetBackground"))
        .containerRelativeFrame(.horizontal)
        .containerRelativeFrame(.vertical)
    }
}
