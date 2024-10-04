//
//  AppColors.swift
//  Runner
//
//  Created by Ruben Daniël Talstra on 04/10/2024.
//

import SwiftUI

struct AppColors {
    // Colors for light mode
    static let lightPrimary = Color(red: 29 / 255, green: 40 / 255, blue: 45 / 255)
    static let lightSecondary = Color(red: 218 / 255, green: 164 / 255, blue: 66 / 255)
    static let lightGreen = Color.green // Adjust this to fit better if needed
    static let lightRed = Color.red // Adjust this to fit better if needed

    // Colors for dark mode
    static let darkPrimary = Color(red: 235 / 255, green: 240 / 255, blue: 245 / 255) // Lighter variant for dark mode
    static let darkSecondary = Color(red: 218 / 255, green: 164 / 255, blue: 66 / 255) // Softer variant of the accent
    static let darkGreen = Color.green.opacity(0.8) // Softer green for dark mode
    static let darkRed = Color.red.opacity(0.8) // Softer red for dark mode
}
