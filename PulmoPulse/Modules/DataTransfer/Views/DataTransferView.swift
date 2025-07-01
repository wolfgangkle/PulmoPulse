//
//  DataTransferView.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 30/06/2025.
//

import SwiftUI

struct DataTransferView: View {
    @EnvironmentObject var patientStore: PatientStore
    @EnvironmentObject var questionnaireStore: QuestionnaireStore

    @State private var showConfirmation = false
    @State private var uploadResult: String?
    @State private var isUploading = false

    @State private var uploadProgress: Double = 0.0
    @State private var progressText: String = ""
    @State private var uploadLogs: [String] = []

    var body: some View {
        VStack(alignment: .center, spacing: 24) {
            Text("Data Transfer")
                .font(.title2)
                .bold()

            VStack(spacing: 8) {
                Text(patientStore.patient.firstName)
                    .font(.title3)
                    .bold()

                Text(patientStore.patient.lastName)
                    .font(.title3)
                    .bold()

                if let dob = patientStore.patient.birthDate {
                    Text(dob.formatted(date: .long, time: .omitted))
                        .foregroundColor(.secondary)
                } else {
                    Text("Date of birth not set")
                        .foregroundColor(.red)
                }
            }

            Text("By sending the data, your recently collected HealthKit values and questionnaire answers will be uploaded to the secure server. After submission, questionnaires can no longer be edited.")
                .font(.footnote)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.top, 16)

            if let uploadResult = uploadResult {
                Text(uploadResult)
                    .font(.footnote)
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
            }

            if isUploading || !uploadLogs.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    if isUploading {
                        ProgressView(value: uploadProgress)
                        Text(progressText)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(uploadLogs, id: \.self) { log in
                                Text(log)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .frame(height: 180)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                    if isUploading {
                        Button("Cancel Upload") {
                            HealthDataManager.shared.isCancelled = true
                            uploadLogs.append("⛔ Upload cancelled.")
                        }
                        .foregroundColor(.red)
                        .padding(.top, 4)
                    }
                }
                .padding(.top, 12)
            }


            Spacer()

            Button(action: {
                showConfirmation = true
            }) {
                if isUploading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Send Data")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(isUploading ? Color.gray : Color.red)
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(isUploading)
            .padding(.top, 16)
            .alert("Are you sure?", isPresented: $showConfirmation) {
                Button("Send", role: .destructive) {
                    isUploading = true
                    uploadResult = nil
                    uploadProgress = 0.0
                    progressText = ""
                    uploadLogs = []

                    // 🔄 Reset cancel flag
                    HealthDataManager.shared.isCancelled = false

                    print("🚀 Uploading data for \(patientStore.patient.fullName)")
                    DataUploader.uploadAll(
                        questionnaireStore: questionnaireStore,
                        patientStore: patientStore,
                        progressHandler: { current, total in
                            uploadProgress = Double(current) / Double(max(total, 1))
                            progressText = "Uploading \(current) of \(total)"
                        },
                        logHandler: { newLog in
                            DispatchQueue.main.async {
                                uploadLogs.append(newLog)
                            }
                        },
                        completion: { result in
                            uploadResult = result
                            isUploading = false
                        }
                    )
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action will send all current patient data to the server.")
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Transfer")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            print("🩺 PatientStore contents: \(patientStore.patient)")
        }
    }
}
