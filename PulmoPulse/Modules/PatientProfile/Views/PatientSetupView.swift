//
//  PatientSetupView.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 30/06/2025.
//

import SwiftUI

struct PatientSetupView: View {
    @EnvironmentObject var patientStore: PatientStore
    @Environment(\.dismiss) var dismiss

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var birthDate: Date = Date()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(NSLocalizedString("patient_info_section", comment: ""))) {
                    TextField(NSLocalizedString("first_name_placeholder", comment: ""), text: $firstName)
                    TextField(NSLocalizedString("last_name_placeholder", comment: ""), text: $lastName)
                    DatePicker(
                        NSLocalizedString("dob_label", comment: ""),
                        selection: $birthDate,
                        displayedComponents: .date
                    )
                }

                Section {
                    Button(action: {
                        let patient = PatientModel(firstName: firstName, lastName: lastName, birthDate: birthDate)
                        print("✅ Saving to patientStore: \(patient)")
                        patientStore.patient = patient
                        dismiss()
                    }) {
                        Text(NSLocalizedString("save_button", comment: ""))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle(NSLocalizedString("patient_setup_title", comment: ""))
        }
        .onAppear {
            let patient = patientStore.patient
            firstName = patient.firstName
            lastName = patient.lastName
            if let dob = patient.birthDate {
                birthDate = dob
            }
        }
    }
}

