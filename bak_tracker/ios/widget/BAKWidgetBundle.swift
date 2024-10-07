//
//  BAKWidgetBundle.swift
//  widget
//
//  Created by Ruben Daniël Talstra on 04/10/2024.
//

import WidgetKit
import SwiftUI

@main
struct BAKWidgetBundle: WidgetBundle {
    var body: some Widget {
        HomeWidget() // Ensure that the widget name corresponds to your main widget file
        LockScreenWidget() // Lock Screen Widgets
    }
}
