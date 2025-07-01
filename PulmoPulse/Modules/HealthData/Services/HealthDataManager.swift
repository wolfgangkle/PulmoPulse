//
//  HealthDataManager.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 30/06/2025.
//

import Foundation
import HealthKit
import FirebaseAuth
import FirebaseFirestore

class HealthDataManager: ObservableObject {
    static let shared = HealthDataManager()

    let healthStore = HKHealthStore()
    private var db: Firestore { Firestore.firestore() }

    @Published var isCancelled = false
    var dataUploadWindowDays: Int = 5  // Adjust to change upload window size

    // 🔌 Registered uploaders
    private lazy var uploaders: [HealthDataUploader] = [
        HeartRateUploader(
            dataTypes: [HKObjectType.quantityType(forIdentifier: .heartRate)!],
            healthStore: healthStore,
            db: db,
            manager: self
        ),
        OxygenSaturationUploader(
            healthStore: healthStore,
            db: db,
            manager: self
        )
    ]

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let typesToRead = Set(uploaders.flatMap { $0.dataTypes })
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, _ in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }

    func uploadAllHealthData(
        progressHandler: @escaping (Int, Int) -> Void,
        logHandler: @escaping (String) -> Void,
        completion: @escaping (Int) -> Void
    ) {
        guard let userId = Auth.auth().currentUser?.uid else {
            logHandler("❌ No authenticated user. Aborting upload.")
            completion(0)
            return
        }

        let startDate = Calendar.current.date(byAdding: .day, value: -dataUploadWindowDays, to: Date())
            ?? Date(timeIntervalSinceNow: -7 * 24 * 3600)

        logHandler("📆 Uploading data from past \(dataUploadWindowDays) days (\(startDate.formatted())).")

        var totalUploaded = 0
        let group = DispatchGroup()

        for uploader in uploaders {
            group.enter()
            uploader.uploadSince(
                startDate: startDate,
                userId: userId,
                progressHandler: progressHandler,
                logHandler: logHandler
            ) { count in
                totalUploaded += count
                group.leave()
            }
        }

        group.notify(queue: .main) {
            logHandler("✅ All uploaders finished. Total uploaded: \(totalUploaded)")
            completion(totalUploaded)
        }
    }

    func uploadPatientMetadata(firstName: String, lastName: String, birthDate: Date?) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user. Skipping metadata upload.")
            return
        }

        var metadata: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        if let birthDate = birthDate {
            metadata["birthDate"] = Timestamp(date: birthDate)
        }

        let docRef = db
            .collection("patients")
            .document(userId)
            .collection("meta")
            .document("meta")

        docRef.setData(metadata, merge: true) { error in
            if let error = error {
                print("❌ Failed to upload patient metadata:", error.localizedDescription)
            } else {
                print("📌 Uploaded patient metadata to Firestore.")
            }
        }
    }

    // MARK: - Upload Metadata Helpers

    func updateLastUploadDate(_ date: Date, userId: String, for type: String) {
        let docRef = db
            .collection("patients")
            .document(userId)
            .collection("meta")
            .document("uploadTracking")

        let fieldName = "last\(type.prefix(1).capitalized)\(type.dropFirst())Upload"

        docRef.setData([
            fieldName: Timestamp(date: date),
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true) { error in
            if let error = error {
                print("❌ Failed to update last upload date for \(type):", error.localizedDescription)
            } else {
                print("📌 Updated \(fieldName) timestamp.")
            }
        }
    }

    /// 👇 NEW: Use last upload date (if not older than maxDaysBack), otherwise fallback to maxDaysBack
    func getEffectiveUploadStartDate(for type: String, userId: String, maxDaysBack: Int = 7, completion: @escaping (Date) -> Void) {
        let docRef = db
            .collection("patients")
            .document(userId)
            .collection("meta")
            .document("uploadTracking")

        let fieldName = "last\(type.prefix(1).capitalized)\(type.dropFirst())Upload"
        let maxAllowed = Calendar.current.date(byAdding: .day, value: -maxDaysBack, to: Date())!

        docRef.getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let timestamp = data[fieldName] as? Timestamp {
                let lastUpload = timestamp.dateValue()
                let effective = max(lastUpload, maxAllowed)
                completion(effective)
            } else {
                completion(maxAllowed)
            }
        }
    }

    var currentUserId: String? {
        return Auth.auth().currentUser?.uid
    }

    func getOverrideStartDate() -> Date {
        let fallbackDays = dataUploadWindowDays
        return Calendar.current.date(byAdding: .day, value: -fallbackDays, to: Date())
            ?? Date(timeIntervalSinceNow: -7 * 24 * 3600)
    }
}

