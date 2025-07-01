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
                Section(header: Text("account_header".localized)) {
                    Button("edit_patient_info".localized) {
                        showingEditPatient = true
                    }
                }

                // Appearance
                Section(header: Text("appearance_header".localized)) {
                    Picker("app_theme".localized, selection: $selectedAppearance) {
                        Text("theme_system".localized).tag("system")
                        Text("theme_light".localized).tag("light")
                        Text("theme_dark".localized).tag("dark")
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text("language_label".localized)
                        Spacer()
                        Text(Locale.currentLanguageDisplayName)
                            .foregroundStyle(.secondary)
                    }

                    Text("language_hint".localized)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }

                // About and Support
                Section(header: Text("about_support_header".localized)) {
                    HStack {
                        Text("version_label".localized)
                        Spacer()
                        Text(appVersion)
                    }
                    HStack {
                        Text("build_label".localized)
                        Spacer()
                        Text(buildNumber)
                    }
                    HStack {
                        Text("developer_label".localized)
                        Spacer()
                        Text("Wolfgang Kleinhaentz")
                    }
                    Link("contact_support".localized, destination: URL(string: "mailto:wolfgang.kleinhaentz@gmail.com")!)
                }

                // Legal
                Section(header: Text("legal_info_header".localized)) {
                    NavigationLink("disclaimer_title".localized) {
                        LegalDetailView(title: "disclaimer_title".localized)
                    }
                    NavigationLink("data_privacy_title".localized) {
                        LegalDetailView(title: "data_privacy_title".localized)
                    }
                    NavigationLink("legal_disclosure_title".localized) {
                        LegalDetailView(title: "legal_disclosure_title".localized)
                    }
                    NavigationLink("copyright_title".localized) {
                        LegalDetailView(title: "copyright_title".localized)
                    }
                }

                // Danger Zone
                Section {
                    Button("erase_all_data_button".localized, role: .destructive) {
                        showingEraseConfirmation = true
                    }
                }
            }
            .navigationTitle("settings_title".localized)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done_button".localized) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEditPatient) {
                PatientSetupView()
                    .environmentObject(patientStore)
            }
            .confirmationDialog(
                "erase_all_confirm_message".localized,
                isPresented: $showingEraseConfirmation,
                titleVisibility: .visible
            ) {
                Button("erase_all_confirm_button".localized, role: .destructive) {
                    UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
                    print("🗑️ All UserDefaults erased")
                }
                Button("cancel_button".localized, role: .cancel) {}
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

struct LegalDetailView: View {
    var title: String

    var body: some View {
        ScrollView {
            Text("legal_detail_placeholder".localized(with: title))
                .padding()
        }
        .navigationTitle(title)
    }
}

// MARK: - Locale helper for language name

extension Locale {
    static var currentLanguageDisplayName: String {
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        return Locale.current.localizedString(forLanguageCode: code)?.capitalized ?? code
    }
}

