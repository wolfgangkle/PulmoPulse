//
//  PatientStore.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 30/06/2025.
//

import Foundation
import Combine

class PatientStore: ObservableObject {
    @Published var patient: PatientModel {
        didSet {
            print("📝 Patient updated in memory: \(patient.fullName)")
            saveToUserDefaults()
        }
    }

    private let storageKey = "savedPatient"

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey) {
            print("📦 Found data in UserDefaults")
            if let decoded = try? JSONDecoder().decode(PatientModel.self, from: data) {
                print("✅ Decoded patient:", decoded.fullName)
                self.patient = decoded
            } else {
                print("❌ Failed to decode stored patient data")
                self.patient = PatientModel(firstName: "", lastName: "", birthDate: nil)
            }
        } else {
            print("⚠️ No patient data found in UserDefaults")
            self.patient = PatientModel(firstName: "", lastName: "", birthDate: nil)
        }
    }

    private func saveToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(patient) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
            print("💾 Saved patient to UserDefaults:", patient.fullName)
        } else {
            print("❌ Failed to encode patient for UserDefaults")
        }
    }

    func clear() {
        print("🧹 Clearing patient data")
        patient = PatientModel(firstName: "", lastName: "", birthDate: nil)
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}

