//
//  HomeWidgetView.swift
//  Runner
//
//  Created by Ruben Daniël Talstra on 04/10/2024.
//

import SwiftUI
import WidgetKit

import SwiftUI
import WidgetKit

struct HomeWidgetView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        switch family {
        case .systemSmall:
            // Layout for systemSmall
            VStack(alignment: .leading) {
                Text(entry.associationName)
                    .font(.headline)
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
                            .font(.title)
                            .foregroundColor(Color.red)
                    }
                    Spacer()
                    VStack {
                        Text("Chucked")
                            .font(.caption)
                            .foregroundColor(Color("CaptionColor"))
                        Text(entry.chucked)
                            .font(.title)
                            .foregroundColor(Color.green)
                    }
                }
            }
            .padding()
            .background(Color("WidgetBackground"))
            .containerRelativeFrame(.horizontal)
            .containerRelativeFrame(.vertical)
        
        case .systemMedium:
            // Layout for larger widget families (systemMedium or systemLarge)
            VStack(alignment: .leading) {
                Text(entry.associationName)
                    .font(.title2)
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
                            .font(.largeTitle)
                            .foregroundColor(Color.red)
                    }
                    Spacer()
                    VStack {
                        Text("Chucked")
                            .font(.caption)
                            .foregroundColor(Color("CaptionColor"))
                        Text(entry.chucked)
                            .font(.largeTitle)
                            .foregroundColor(Color.green)
                    }
                    Spacer()
                    VStack {
                        Text("Bets Won")
                            .font(.caption)
                            .foregroundColor(Color("CaptionColor"))
                        Text(entry.betsWon)
                            .font(.largeTitle)
                            .foregroundColor(Color.blue)
                    }
                    Spacer()
                    VStack {
                        Text("Bets Lost")
                            .font(.caption)
                            .foregroundColor(Color("CaptionColor"))
                        Text(entry.betsLost)
                            .font(.largeTitle)
                            .foregroundColor(Color.red)
                    }
                }
            }
         .padding()
        .background(Color("WidgetBackground"))
        .containerRelativeFrame(.horizontal)
        .containerRelativeFrame(.vertical)
        
        default:
            EmptyView() // Fallback for unsupported widget families
        }
    }
}
