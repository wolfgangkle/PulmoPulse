//
//  SettingsView.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 01/07/2025.
//


import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var patientStore: PatientStore
    @Environment(\.dismiss) var dismiss
    @State private var showingEditPatient = false
    @AppStorage("appearance") private var selectedAppearance: String = "system"
    @State private var showingEraseConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                // Patient
                Section(header: Text("Account")) {
                    Button("Edit Patient Info") {
                        showingEditPatient = true
                    }
                }

                // Appearance
                Section(header: Text("Appearance")) {
                    Picker("App Theme", selection: $selectedAppearance) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.segmented)
                }


                // About and Support
                Section(header: Text("About and Support")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                    }
                    HStack {
                        Text("Build")
                        Spacer()
                        Text(buildNumber)
                    }
                    HStack {
                        Text("Developer")
                        Spacer()
                        Text("Wolfgang Kleinhaentz")
                    }
                    Link("Contact Support", destination: URL(string: "mailto:wolfgang.kleinhaentz@gmail.com")!)
                }

                // Legal
                Section(header: Text("Legal Information")) {
                    NavigationLink("Disclaimer") {
                        LegalDetailView(title: "Disclaimer")
                    }
                    NavigationLink("Data Privacy") {
                        LegalDetailView(title: "Data Privacy")
                    }
                    NavigationLink("Legal Disclosure") {
                        LegalDetailView(title: "Legal Disclosure")
                    }
                    NavigationLink("Copyright") {
                        LegalDetailView(title: "Copyright")
                    }
                }

                // Danger Zone
                Section {
                    Button("Erase All Local Data", role: .destructive) {
                        showingEraseConfirmation = true
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEditPatient) {
                PatientSetupView()
                    .environmentObject(patientStore)
            }
            .confirmationDialog("Are you sure you want to erase all local data? This cannot be undone.", isPresented: $showingEraseConfirmation, titleVisibility: .visible) {
                Button("Erase All Data", role: .destructive) {
                    UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
                    print("🗑️ All UserDefaults erased")
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
}


// MARK: - Placeholder Legal Detail View
struct LegalDetailView: View {
    var title: String

    var body: some View {
        ScrollView {
            Text("This is the \(title) page.")
                .padding()
        }
        .navigationTitle(title)
    }
}
