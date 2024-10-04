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
        SimpleEntry(date: Date(), associationName: "Association", chucked: "0", debt: "0")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let prefs = UserDefaults(suiteName: "group.com.baktracker.shared")
        let associationName = prefs?.string(forKey: "association_name") ?? "Association"
        let chucked = prefs?.string(forKey: "chucked_drinks") ?? "0"
        let debt = prefs?.string(forKey: "drink_debt") ?? "0"
        let entry = SimpleEntry(date: Date(), associationName: associationName, chucked: chucked, debt: debt)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let prefs = UserDefaults(suiteName: "group.com.baktracker.shared")
        let associationName = prefs?.string(forKey: "association_name") ?? "Association"
        let chucked = prefs?.string(forKey: "chucked_drinks") ?? "0"
        let debt = prefs?.string(forKey: "drink_debt") ?? "0"

        let currentDate = Date()
        let entry = SimpleEntry(date: currentDate, associationName: associationName, chucked: chucked, debt: debt)

        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let associationName: String
    let chucked: String
    let debt: String
}
