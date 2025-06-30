//
//  DataTransferView.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 30/06/2025.
//

import SwiftUI

struct DataTransferView: View {
    @EnvironmentObject var patientStore: PatientStore

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Patient Info")
                .font(.title2)
                .bold()

            VStack(alignment: .leading, spacing: 8) {
                if patientStore.patient.firstName.isEmpty && patientStore.patient.lastName.isEmpty {
                    Text("⚠️ Patient name is not set.")
                        .foregroundColor(.red)
                } else {
                    Text("👤 \(patientStore.patient.fullName)")
                        .font(.headline)
                }

                if let dob = patientStore.patient.birthDate {
                    Text("🎂 \(dob.formatted(date: .long, time: .omitted))")
                        .foregroundColor(.secondary)
                } else {
                    Text("🎂 Date of birth not set")
                        .foregroundColor(.red)
                }
            }

            Spacer()

            Button(action: {
                print("🚀 Uploading data for \(patientStore.patient.fullName)")
                // TODO: Add actual upload logic
            }) {
                Text("Send Data")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Transfer")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.white)
        .onAppear {
            print("🩺 PatientStore contents: \(patientStore.patient)")
        }
    }
}

