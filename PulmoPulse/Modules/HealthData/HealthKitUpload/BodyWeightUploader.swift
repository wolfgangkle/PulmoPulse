//
//  BodyWeightUploader.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 01/07/2025.
//

import Foundation
import HealthKit
import FirebaseFirestore

struct BodyWeightUploader: HealthDataUploader {
    var dataTypes: [HKObjectType]

    let healthStore: HKHealthStore
    let db: Firestore
    weak var manager: HealthDataManager?

    var typeIdentifier: String { "bodyWeight" }

    func fetchSamples(
        since _: Date,
        log: @escaping (String) -> Void,
        completion: @escaping ([HKQuantitySample]) -> Void
    ) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            log("❌ " + NSLocalizedString("body_weight_type_missing", comment: ""))
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
                log("❌ " + String(format: NSLocalizedString("body_weight_fetch_failed", comment: ""), error?.localizedDescription ?? "Unknown error"))
                completion([])
                return
            }

            log("⚖️ " + String(format: NSLocalizedString("body_weight_fetched", comment: ""), samples.count))
            completion(samples)
        }

        log("📥 " + NSLocalizedString("body_weight_querying", comment: ""))
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
        let unit = HKUnit.gramUnit(with: .kilo)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var latestPerDay: [String: HKQuantitySample] = [:]

        for sample in samples {
            if manager?.isCancelled == true { break }

            let dateKey = formatter.string(from: sample.startDate)
            if let existing = latestPerDay[dateKey] {
                if sample.startDate > existing.startDate {
                    latestPerDay[dateKey] = sample
                }
            } else {
                latestPerDay[dateKey] = sample
            }
        }

        let total = latestPerDay.count
        var uploaded = 0
        let group = DispatchGroup()
        var latestDate: Date?

        // ✅ Log initial status
        log("⚖️ " + String(format: NSLocalizedString("body_weight_upload_progress", comment: ""), uploaded, total))

        for (dateKey, sample) in latestPerDay {
            if manager?.isCancelled == true { break }

            let weightKg = sample.quantity.doubleValue(for: unit)
            let roundedKg = round(weightKg * 10) / 10.0
            let date = calendar.startOfDay(for: sample.startDate)
            latestDate = max(latestDate ?? date, date)

            let data: [String: Any] = [
                "date": Timestamp(date: date),
                "kg": roundedKg,
                "type": typeIdentifier
            ]

            group.enter()
            db.collection("patients")
                .document(userId)
                .collection("healthData")
                .document("bodyWeight")
                .collection("daily")
                .document(dateKey)
                .setData(data) { error in
                    if let error = error {
                        log("❌ " + String(format: NSLocalizedString("body_weight_upload_failed", comment: ""), dateKey, error.localizedDescription))
                    } else {
                        uploaded += 1
                        progress(uploaded, total)

                        // ✅ Inline progress update
                        log("⚖️ " + String(format: NSLocalizedString("body_weight_upload_progress", comment: ""), uploaded, total))
                    }
                    group.leave()
                }
        }

        group.notify(queue: .main) {
            if let latest = latestDate {
                manager?.updateLastUploadDate(latest, userId: userId, for: typeIdentifier)
            }
            completion(uploaded)
        }
    }
}
