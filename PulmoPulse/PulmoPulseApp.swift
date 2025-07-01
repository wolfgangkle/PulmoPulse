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
                    // ✅ Safe to call AFTER FirebaseApp.configure()
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

                    // 🔐 Request HealthKit access on first launch
                    HealthDataManager.shared.requestAuthorization { granted in
                        print(granted ? "✅ HealthKit access granted" : "❌ HealthKit access denied")
                    }

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

