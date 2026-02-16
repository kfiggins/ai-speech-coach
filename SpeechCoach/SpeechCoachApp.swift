//
//  SpeechCoachApp.swift
//  SpeechCoach
//
//  Created by AI Speech Coach
//

import SwiftUI

@main
struct SpeechCoachApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
