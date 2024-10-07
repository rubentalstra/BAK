//
//  LockScreenWidgetView.swift
//  BAKLockScreenWidget
//
//  Created by Ruben Daniël Talstra on 06/10/2024.
//

import SwiftUI
import WidgetKit

struct LockScreenWidgetView: View {
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
            VStack(alignment: .leading, spacing: 6) {
                // Association name
                Text(entry.associationName)
                    .font(.headline) // Increased the base font size
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8) // Slightly higher scale factor to ensure text remains readable
                    .padding(.bottom, 4)

                HStack(spacing: 12) {
                    // Left column: BAK debt and Chucked drinks
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "mug.fill") // Beer mug icon for debt
                                .foregroundColor(.orange)
                            Text(entry.debt)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                        }
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill") // Checkmark for chucked drinks
                                .foregroundColor(.green)
                            Text(entry.chucked)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                    }

                    Spacer()

                    // Right column: Bets won and Bets lost
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "trophy.fill") // Trophy for bets won
                                .foregroundColor(.blue)
                            Text(entry.betsWon)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        HStack(spacing: 4) {
                            Image(systemName: "dice.fill") // Dice for bets lost
                                .foregroundColor(.red)
                            Text(entry.betsLost)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .padding(.vertical, 6)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(entry.associationName). BAK debt is \(entry.debt) beers. Chucked drinks are \(entry.chucked) beers. Bets won: \(entry.betsWon), Bets lost: \(entry.betsLost)")
            
        default:
            EmptyView()
        }
    }
}
