//
//  HeartRateUploader.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 01/07/2025.
//

import Foundation
import HealthKit
import FirebaseFirestore

struct HeartRateUploader: HealthDataUploader {
    var dataTypes: [HKObjectType]

    let healthStore: HKHealthStore
    let db: Firestore
    weak var manager: HealthDataManager?

    var typeIdentifier: String { "heartRate" }

    func fetchSamples(
        since startDate: Date,
        log: @escaping (String) -> Void,
        completion: @escaping ([HKQuantitySample]) -> Void
    ) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            log("❌ " + NSLocalizedString("heart_rate_type_missing", comment: ""))
            completion([])
            return
        }

        let start = Calendar.current.startOfDay(for: startDate)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: [])
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(
            sampleType: type,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sort]
        ) { _, results, error in
            guard let samples = results as? [HKQuantitySample], error == nil else {
                log("❌ " + String(format: NSLocalizedString("heart_rate_fetch_failed", comment: ""), error?.localizedDescription ?? "Unknown error"))
                completion([])
                return
            }

            log("📊 " + String(format: NSLocalizedString("heart_rate_fetched", comment: ""), samples.count))
            completion(samples)
        }

        log("💓 " + String(format: NSLocalizedString("heart_rate_querying", comment: ""), start.formatted()))
        healthStore.execute(query)
    }

    func uploadSamples(
        _ samples: [HKQuantitySample],
        userId: String,
        progress: @escaping (Int, Int) -> Void,
        log: @escaping (String) -> Void,
        completion: @escaping (Int) -> Void
    ) {
        let bpmUnit = HKUnit(from: "count/min")
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var grouped: [String: [Double]] = [:]

        for sample in samples {
            if manager?.isCancelled == true { break }
            let value = sample.quantity.doubleValue(for: bpmUnit)
            let dateKey = formatter.string(from: sample.startDate)
            grouped[dateKey, default: []].append(value)
        }

        let total = grouped.count
        var uploaded = 0
        let group = DispatchGroup()
        var latestDate: Date?

        // ✅ Log initial inline progress
        log("💓 " + String(format: NSLocalizedString("heart_rate_upload_progress", comment: ""), uploaded, total))

        for (dateKey, values) in grouped {
            guard !values.isEmpty else { continue }

            let minValue = values.min() ?? 0
            let maxValue = values.max() ?? 0
            let avg = values.reduce(0, +) / Double(values.count)

            let roundedMin = round(minValue * 10) / 10.0
            let roundedMax = round(maxValue * 10) / 10.0
            let roundedAvg = round(avg * 10) / 10.0

            let date = formatter.date(from: dateKey) ?? Date()
            latestDate = max(latestDate ?? date, date)

            let data: [String: Any] = [
                "date": Timestamp(date: date),
                "bpmAvg": roundedAvg,
                "bpmMin": roundedMin,
                "bpmMax": roundedMax,
                "type": typeIdentifier
            ]

            group.enter()
            db.collection("patients")
                .document(userId)
                .collection("healthData")
                .document("heartRate")
                .collection("daily")
                .document(dateKey)
                .setData(data) { error in
                    if let error = error {
                        log("❌ " + String(format: NSLocalizedString("heart_rate_upload_failed", comment: ""), dateKey, error.localizedDescription))
                    } else {
                        uploaded += 1
                        progress(uploaded, total)

                        // ✅ Update progress line
                        log("💓 " + String(format: NSLocalizedString("heart_rate_upload_progress", comment: ""), uploaded, total))
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
