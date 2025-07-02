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
                Section(header: Text(NSLocalizedString("account_header", comment: ""))) {
                    Button(NSLocalizedString("edit_patient_info", comment: "")) {
                        showingEditPatient = true
                    }
                }

                // Appearance
                Section(header: Text(NSLocalizedString("appearance_header", comment: ""))) {
                    Picker(NSLocalizedString("app_theme", comment: ""), selection: $selectedAppearance) {
                        Text(NSLocalizedString("theme_system", comment: "")).tag("system")
                        Text(NSLocalizedString("theme_light", comment: "")).tag("light")
                        Text(NSLocalizedString("theme_dark", comment: "")).tag("dark")
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text(NSLocalizedString("language_label", comment: ""))
                        Spacer()
                        Text(Locale.currentLanguageDisplayName)
                            .foregroundStyle(.secondary)
                    }

                    Text(NSLocalizedString("language_hint", comment: ""))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }

                // About and Support
                Section(header: Text(NSLocalizedString("about_support_header", comment: ""))) {
                    HStack {
                        Text(NSLocalizedString("version_label", comment: ""))
                        Spacer()
                        Text(appVersion)
                    }
                    HStack {
                        Text(NSLocalizedString("build_label", comment: ""))
                        Spacer()
                        Text(buildNumber)
                    }
                    HStack {
                        Text(NSLocalizedString("developer_label", comment: ""))
                        Spacer()
                        Text("Wolfgang Kleinhaentz")
                    }
                    Link(NSLocalizedString("contact_support", comment: ""), destination: URL(string: "mailto:wolfgang.kleinhaentz@gmail.com")!)
                }

                // Legal
                Section(header: Text(NSLocalizedString("legal_info_header", comment: ""))) {
                    NavigationLink(NSLocalizedString("disclaimer_title", comment: "")) {
                        LegalDetailView(title: NSLocalizedString("disclaimer_title", comment: ""), bodyKey: "disclaimer_body")
                    }
                    NavigationLink(NSLocalizedString("data_privacy_title", comment: "")) {
                        LegalDetailView(title: NSLocalizedString("data_privacy_title", comment: ""), bodyKey: "data_privacy_body")
                    }
                    NavigationLink(NSLocalizedString("legal_disclosure_title", comment: "")) {
                        LegalDetailView(title: NSLocalizedString("legal_disclosure_title", comment: ""), bodyKey: "legal_disclosure_body")
                    }
                    NavigationLink(NSLocalizedString("copyright_title", comment: "")) {
                        LegalDetailView(title: NSLocalizedString("copyright_title", comment: ""), bodyKey: "copyright_body")
                    }
                }

                // Danger Zone
                Section {
                    Button(NSLocalizedString("erase_all_data_button", comment: ""), role: .destructive) {
                        showingEraseConfirmation = true
                    }
                }
            }
            .navigationTitle(NSLocalizedString("settings_title", comment: ""))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("done_button", comment: "")) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEditPatient) {
                PatientSetupView()
                    .environmentObject(patientStore)
            }
            .confirmationDialog(
                NSLocalizedString("erase_all_confirm_message", comment: ""),
                isPresented: $showingEraseConfirmation,
                titleVisibility: .visible
            ) {
                Button(NSLocalizedString("erase_all_confirm_button", comment: ""), role: .destructive) {
                    UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
                    print("🗑️ All UserDefaults erased")
                }
                Button(NSLocalizedString("cancel_button", comment: ""), role: .cancel) {}
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

// MARK: - Legal Detail View

struct LegalDetailView: View {
    var title: String
    var bodyKey: String

    var body: some View {
        ScrollView {
            Text(NSLocalizedString(bodyKey, comment: ""))
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

// MARK: - Dummy localization keys for string extraction
private func _registerLegalLocalizationKeys() {
    _ = NSLocalizedString("disclaimer_body", comment: "Body text for Disclaimer")
    _ = NSLocalizedString("data_privacy_body", comment: "Body text for Data Privacy")
    _ = NSLocalizedString("legal_disclosure_body", comment: "Body text for Legal Disclosure")
    _ = NSLocalizedString("copyright_body", comment: "Body text for Copyright")
}

