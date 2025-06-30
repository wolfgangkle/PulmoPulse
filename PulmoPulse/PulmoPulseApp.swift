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

    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.titleTextAttributes = [.foregroundColor: UIColor.red]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.red]

        let proxy = UINavigationBar.appearance()
        proxy.standardAppearance = appearance
        proxy.scrollEdgeAppearance = appearance
        proxy.compactAppearance = appearance
        proxy.compactScrollEdgeAppearance = appearance
        proxy.tintColor = .red // ← most important for back button
    }

    var body: some Scene {
        WindowGroup {
            NavigationView { // <- YES: use NavigationView instead of NavigationStack for best UIKit compatibility
                HomeView()
                    .environmentObject(questionnaireStore)
            }
        }
    }
}


