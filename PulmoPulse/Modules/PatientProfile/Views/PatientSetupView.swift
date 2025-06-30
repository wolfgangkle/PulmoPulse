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
                Section(header: Text("Patient Information")) {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    DatePicker("Date of Birth", selection: $birthDate, displayedComponents: .date)
                }

                Section {
                    Button("Save") {
                        let patient = PatientModel(firstName: firstName, lastName: lastName, birthDate: birthDate)
                        print("✅ Saving to patientStore: \(patient)")
                        patientStore.patient = patient // 🔴 This updates AND saves it
                        dismiss()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Patient Setup")
        }
        .onAppear {
            // Preload existing patient info if it exists
            let patient = patientStore.patient
            firstName = patient.firstName
            lastName = patient.lastName
            if let dob = patient.birthDate {
                birthDate = dob
            }
        }
    }
}

