//
//  PulmoPulseApp.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 30/06/2025.
//

import SwiftUI

@main
struct PulmoPulseApp: App {
    @StateObject private var questionnaireStore = QuestionnaireStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(questionnaireStore)
        }
    }
}

