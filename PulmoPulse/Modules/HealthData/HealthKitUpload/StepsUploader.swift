//
//  SleepUploader.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 01/07/2025.
//

import Foundation
import HealthKit
import FirebaseFirestore

struct SleepUploader: HealthDataUploader {
    var dataTypes: [HKObjectType]
    
    let healthStore: HKHealthStore
    let db: Firestore
    weak var manager: HealthDataManager?

    var typeIdentifier: String { "sleep" }

    func fetchSamples(since startDate: Date, log: @escaping (String) -> Void, completion: @escaping ([HKQuantitySample]) -> Void) {
        guard let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            log("❌ Sleep type unavailable.")
            completion([])
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: [])
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, results, error in
            guard let samples = results as? [HKCategorySample], error == nil else {
                log("❌ Sleep fetch error: \(error?.localizedDescription ?? "unknown")")
                completion([])
                return
            }

            log("✅ Fetched \(samples.count) sleep samples.")
            // Hack: Map to dummy HKQuantitySample to reuse upload logic
            let quantitySamples = samples.map {
                HKQuantitySample(
                    type: HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
                    quantity: HKQuantity(unit: .count(), doubleValue: Double($0.value)),
                    start: $0.startDate,
                    end: $0.endDate
                )
            }
            completion(quantitySamples)
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
            .document("sleep")
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
            let value = Int(sample.quantity.doubleValue(for: .count()))
            let start = sample.startDate.timeIntervalSince1970
            let end = sample.endDate.timeIntervalSince1970
            latestTimestamp = max(latestTimestamp, end)

            let data: [String: Any] = [
                "type": "sleep",
                "category": value, // 0 = inBed, 1 = asleep, etc.
                "start": start,
                "end": end
            ]

            collection.addDocument(data: data) { error in
                if let error = error {
                    log("❌ Upload error \(index + 1): \(error.localizedDescription)")
                } else {
                    uploaded += 1
                    log("✅ Uploaded sleep sample \(index + 1) / \(total)")
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

