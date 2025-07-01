//
//  OxygenSaturationUploader.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 01/07/2025.
//


import Foundation
import HealthKit
import FirebaseFirestore

class OxygenSaturationUploader: HealthDataUploader {
    let typeIdentifier = "oxygenSaturation"
    let typeName = "oxygenSaturation"
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
        since _: Date,
        log: @escaping (String) -> Void,
        completion: @escaping ([HKQuantitySample]) -> Void
    ) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) else {
            log("❌ " + NSLocalizedString("oxygen_type_unavailable", comment: ""))
            completion([])
            return
        }

        let calendar = Calendar.current
        let fallback = calendar.date(byAdding: .day, value: -7, to: Date())!
        let startDate = calendar.startOfDay(for: manager?.getOverrideStartDate() ?? fallback)
        let endDate = Date()

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(
            sampleType: type,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sort]
        ) { _, results, error in
            guard let samples = results as? [HKQuantitySample], error == nil else {
                log("❌ " + String(format: NSLocalizedString("oxygen_fetch_failed", comment: ""), error?.localizedDescription ?? "Unknown error"))
                completion([])
                return
            }

            log("🫁 " + String(format: NSLocalizedString("oxygen_samples_fetched", comment: ""), samples.count))
            completion(samples)
        }

        log("🫁 " + NSLocalizedString("oxygen_querying", comment: ""))
        healthStore.execute(query)
    }

    func uploadSamples(
        _ samples: [HKQuantitySample],
        userId: String,
        progress: @escaping (Int, Int) -> Void,
        log: @escaping (String) -> Void,
        completion: @escaping (Int) -> Void
    ) {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var grouped: [String: [Double]] = [:]

        for sample in samples {
            if manager?.isCancelled == true { break }

            let value = sample.quantity.doubleValue(for: .percent()) * 100.0
            let dateKey = formatter.string(from: sample.startDate)
            grouped[dateKey, default: []].append(value)
        }

        let total = grouped.count
        var uploaded = 0
        let group = DispatchGroup()
        var latestDate: Date?

        for (dateKey, values) in grouped {
            guard !values.isEmpty else { continue }

            let avgValue = values.reduce(0, +) / Double(values.count)
            let minValue = values.min() ?? avgValue
            let maxValue = values.max() ?? avgValue

            let roundedAvg = Int(round(avgValue))
            let roundedMin = Int(round(minValue))
            let roundedMax = Int(round(maxValue))

            let date = formatter.date(from: dateKey) ?? Date()
            latestDate = max(latestDate ?? date, date)

            let data: [String: Any] = [
                "date": Timestamp(date: date),
                "type": typeIdentifier,
                "avgSpO2": roundedAvg,
                "minSpO2": roundedMin,
                "maxSpO2": roundedMax
            ]

            group.enter()
            db.collection("patients")
                .document(userId)
                .collection("healthData")
                .document(typeIdentifier)
                .collection("daily")
                .document(dateKey)
                .setData(data) { error in
                    if let error = error {
                        log("❌ " + String(format: NSLocalizedString("oxygen_upload_failed", comment: ""), dateKey, error.localizedDescription))
                    } else {
                        uploaded += 1
                        log("✅ " + String(format: NSLocalizedString("oxygen_uploaded", comment: ""), dateKey, roundedAvg))
                        progress(uploaded, total)
                    }
                    group.leave()
                }
        }

        group.notify(queue: .main) {
            if let latest = latestDate {
                self.manager?.updateLastUploadDate(latest, userId: userId, for: self.typeIdentifier)
            }
            completion(uploaded)
        }
    }
}
