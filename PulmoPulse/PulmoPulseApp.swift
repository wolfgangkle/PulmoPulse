//
//  PulmoPulseApp.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 30/06/2025.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct PulmoPulseApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var questionnaireStore = QuestionnaireStore()
    @StateObject private var patientStore = PatientStore()
    @State private var showPatientSetup = false

    // 👇 Persisted theme selection
    @AppStorage("appearance") private var appearance: String = "system"

    var body: some Scene {
        WindowGroup {
            NavigationView {
                ZStack {
                    HomeView()
                        .environmentObject(questionnaireStore)
                        .environmentObject(patientStore)
                        .disabled(showPatientSetup)
                }
                .sheet(isPresented: $showPatientSetup) {
                    PatientSetupView()
                        .environmentObject(patientStore)
                }
                .onAppear {
                    if Auth.auth().currentUser == nil {
                        Auth.auth().signInAnonymously { result, error in
                            if let error = error {
                                print("❌ Firebase anonymous sign-in failed:", error.localizedDescription)
                            } else if let user = result?.user {
                                print("✅ Firebase signed in anonymously. UID:", user.uid)
                            }
                        }
                    } else {
                        print("✅ Already signed in. UID:", Auth.auth().currentUser?.uid ?? "unknown")
                    }

                    HealthDataManager.shared.requestAuthorization { granted in
                        print(granted ? "✅ HealthKit access granted" : "❌ HealthKit access denied")
                    }

                    if patientStore.patient.firstName.isEmpty ||
                        patientStore.patient.lastName.isEmpty ||
                        patientStore.patient.birthDate == nil {
                        showPatientSetup = true
                    }
                }
            }
            .preferredColorScheme(colorSchemeFrom(appearance)) // 👈 Appearance applied here
            .tint(.red) // 👈 Global red tint
        }
    }

    // 👇 Helper function to resolve color scheme
    func colorSchemeFrom(_ setting: String) -> ColorScheme? {
        switch setting {
        case "light": return .light
        case "dark": return .dark
        default: return nil // 'system' = follow device
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

