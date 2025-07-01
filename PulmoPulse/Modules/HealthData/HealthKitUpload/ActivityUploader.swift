//
//  ActivityUploader.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 01/07/2025.
//

import Foundation
import HealthKit
import FirebaseFirestore

struct ActivityUploader: HealthDataUploader {
    var dataTypes: [HKObjectType]

    let healthStore: HKHealthStore
    let db: Firestore
    weak var manager: HealthDataManager?

    var typeIdentifier: String { "activity" }

    func fetchSamples(since startDate: Date, log: @escaping (String) -> Void, completion: @escaping ([HKQuantitySample]) -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            log("❌ Active Energy Burned type unavailable.")
            completion([])
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: [])
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, results, error in
            guard let samples = results as? [HKQuantitySample], error == nil else {
                log("❌ Activity fetch error: \(error?.localizedDescription ?? "unknown")")
                completion([])
                return
            }

            log("✅ Fetched \(samples.count) activity samples.")
            completion(samples)
        }

        healthStore.execute(query)
    }

    func uploadSamples(
        _ samples: [HKQuantitySample],
        userId: String,
        progress: @escaping (Int, Int) -> Void,
        log: @escaping (String) -> Void,
        completion: @escaping (Int) -> Void
    ) {
        let collection = db
            .collection("patients")
            .document(userId)
            .collection("healthData")
            .document("activity")
            .collection("samples")

        let total = samples.count
        var uploaded = 0
        var latestTimestamp: TimeInterval = 0

        func uploadNext(index: Int) {
            if index >= total {
                if uploaded > 0 && !(manager?.isCancelled ?? false) {
                    let lastDate = Date(timeIntervalSince1970: latestTimestamp)
                    manager?.updateLastUploadDate(lastDate, userId: userId, for: typeIdentifier)
                }
                completion(uploaded)
                return
            }

            if manager?.isCancelled == true {
                log("⏹️ Upload cancelled by user after \(uploaded) samples.")
                completion(uploaded)
                return
            }

            let sample = samples[index]
            let kcal = sample.quantity.doubleValue(for: HKUnit.kilocalorie())
            let start = sample.startDate.timeIntervalSince1970
            let end = sample.endDate.timeIntervalSince1970
            latestTimestamp = max(latestTimestamp, end)

            let data: [String: Any] = [
                "type": "activity",
                "kcal": kcal,
                "start": start,
                "end": end,
                "source": sample.sourceRevision.source.name
            ]

            collection.addDocument(data: data) { error in
                if let error = error {
                    log("❌ Upload error \(index + 1): \(error.localizedDescription)")
                } else {
                    uploaded += 1
                    log("✅ Uploaded activity sample \(index + 1) / \(total)")
                }

                progress(uploaded, total)

                DispatchQueue.global().asyncAfter(deadline: .now() + 0.005) {
                    uploadNext(index: index + 1)
                }
            }
        }

        uploadNext(index: 0)
    }
}

