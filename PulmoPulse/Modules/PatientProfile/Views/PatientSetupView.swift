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
                Section(header: Text("patient_info_section".localized)) {
                    TextField("first_name_placeholder".localized, text: $firstName)
                    TextField("last_name_placeholder".localized, text: $lastName)
                    DatePicker("dob_label".localized, selection: $birthDate, displayedComponents: .date)
                }

                Section {
                    Button(action: {
                        let patient = PatientModel(firstName: firstName, lastName: lastName, birthDate: birthDate)
                        print("✅ Saving to patientStore: \(patient)")
                        patientStore.patient = patient
                        dismiss()
                    }) {
                        Text("save_button".localized)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("patient_setup_title".localized)
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

