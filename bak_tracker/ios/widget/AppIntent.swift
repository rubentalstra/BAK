//
//  AppIntent.swift
//  widget
//
//  Created by Ruben Daniël Talstra on 04/10/2024.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Drink & Debt Configuration" }
    static var description: IntentDescription { "Configure the drink consumption and debt widget for the association." }

    // Configurable parameters for the widget.
    @Parameter(title: "Maximum Drink Debt", default: 10)
    var maxDrinkDebt: Int

    @Parameter(title: "Display Unit", default: "Drinks")
    var displayUnit: String

    @Parameter(title: "Association Name", default: "Unknown")
    var associationName: String
}