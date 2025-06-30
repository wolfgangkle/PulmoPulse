//
//  PulmoPulseApp.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 30/06/2025.
//

import SwiftUI
import FirebaseCore

@main
struct PulmoPulseApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var questionnaireStore = QuestionnaireStore()
    @StateObject private var patientStore = PatientStore()
    @State private var showPatientSetup = false

    init() {
        // UINavigationBar styling
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
        proxy.tintColor = .red

        // 🔴 Request HealthKit authorization at launch
        HealthDataManager.shared.requestAuthorization { granted in
            print(granted ? "✅ HealthKit access granted" : "❌ HealthKit access denied")
        }
    }

    var body: some Scene {
        WindowGroup {
            NavigationView {
                ZStack {
                    HomeView()
                        .environmentObject(questionnaireStore)
                        .environmentObject(patientStore)
                        .disabled(showPatientSetup) // prevent tapping behind sheet
                }
                .sheet(isPresented: $showPatientSetup) {
                    PatientSetupView()
                        .environmentObject(patientStore)
                }
                .onAppear {
                    // Show PatientSetupView if no valid patient data
                    if patientStore.patient.firstName.isEmpty ||
                       patientStore.patient.lastName.isEmpty ||
                       patientStore.patient.birthDate == nil {
                        showPatientSetup = true
                    }
                }
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

