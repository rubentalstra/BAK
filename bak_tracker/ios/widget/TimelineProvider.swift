//
//  TimelineProvider.swift
//  Runner
//
//  Created by Ruben Daniël Talstra on 04/10/2024.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), associationName: "Association", debt: "0", chucked: "0", betsWon:  "0", betsLost: "0"   )
    }

    // Snapshot method for fast-loading widget previews
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = SimpleEntry(date: Date(), associationName: "Association", debt: "5", chucked: "10", betsWon:  "15", betsLost: "5"  )
        completion(entry)
    }
    
    // Timeline method to fetch the data and schedule updates
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        // Fetch data from shared storage (UserDefaults with app group identifier)
        let entry = fetchEntry()
        
        // Set a timeline policy to refresh the widget more frequently (e.g., every 5 minutes)
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 5, to: Date()) ?? Date().addingTimeInterval(5 * 60)
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        
        completion(timeline)
    }
    
    // Consolidate data fetching logic
    private func fetchEntry() -> SimpleEntry {
        let UserDefaults = UserDefaults(suiteName: "group.com.baktracker.shared")
        let associationName = UserDefaults?.string(forKey: "association_name") ?? "No Association"
        let chucked = UserDefaults?.string(forKey: "chucked_drinks") ?? "0"
        let debt = UserDefaults?.string(forKey: "drink_debt") ?? "0"
        let betsWon = UserDefaults?.string(forKey: "bets_won") ?? "0"
        let betsLost = UserDefaults?.string(forKey: "bets_lost") ?? "0"

        return SimpleEntry(date: Date(), associationName: associationName, debt: debt, chucked: chucked, betsWon: betsWon, betsLost: betsLost)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let associationName: String
    let debt: String
    let chucked: String
    let betsWon: String
    let betsLost: String
}
