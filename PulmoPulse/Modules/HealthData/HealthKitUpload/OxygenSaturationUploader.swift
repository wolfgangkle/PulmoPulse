//
//  OxygenSaturationUploader.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 01/07/2025.
//

import Foundation
import HealthKit
import FirebaseFirestore
import FirebaseAuth

class OxygenSaturationUploader: HealthDataUploader {
    let typeIdentifier: String = "oxygenSaturation"
    let typeName: String = "oxygenSaturation"
    let dataTypes: [HKObjectType]

    let healthStore: HKHealthStore
    let db: Firestore
    weak var manager: HealthDataManager?

    init(healthStore: HKHealthStore, db: Firestore, manager: HealthDataManager?) {
        self.healthStore = healthStore
        self.db = db
        self.manager = manager
        self.dataTypes = [HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!]
    }

    func fetchSamples(
        since startDate: Date,
        log: @escaping (String) -> Void,
        completion: @escaping ([HKQuantitySample]) -> Void
    ) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) else {
            log("❌ Could not create HKQuantityType for oxygen saturation")
            completion([])
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: [])
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, results, error in
            guard let samples = results as? [HKQuantitySample], error == nil else {
                log("❌ Oxygen saturation fetch error: \(error?.localizedDescription ?? "Unknown")")
                completion([])
                return
            }
            log("✅ Fetched \(samples.count) oxygen saturation samples.")
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
            .document(typeName)
            .collection("samples")

        var uploaded = 0
        let total = samples.count
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
                log("⏹️ Upload cancelled after \(uploaded) samples.")
                completion(uploaded)
                return
            }

            let sample = samples[index]
            let saturation = sample.quantity.doubleValue(for: .percent()) * 100.0
            let start = sample.startDate.timeIntervalSince1970
            let end = sample.endDate.timeIntervalSince1970
            latestTimestamp = max(latestTimestamp, end)

            let data: [String: Any] = [
                "type": typeName,
                "oxygenPercentage": saturation,
                "start": start,
                "end": end,
                "source": sample.sourceRevision.source.name
            ]

            collection.addDocument(data: data) { error in
                if error == nil {
                    uploaded += 1
                    log("✅ Uploaded sample \(index + 1) / \(total)")
                } else {
                    log("❌ Sample \(index + 1) failed: \(error?.localizedDescription ?? "unknown error")")
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

