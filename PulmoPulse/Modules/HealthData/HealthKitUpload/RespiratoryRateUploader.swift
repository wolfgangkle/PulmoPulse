//
//  RespiratoryRateUploader.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 01/07/2025.
//


import Foundation
import HealthKit
import FirebaseFirestore

struct RespiratoryRateUploader: HealthDataUploader {
    var dataTypes: [HKObjectType]

    let healthStore: HKHealthStore
    let db: Firestore
    weak var manager: HealthDataManager?

    var typeIdentifier: String { "respiratoryRate" }

    func fetchSamples(
        since startDate: Date,
        log: @escaping (String) -> Void,
        completion: @escaping ([HKQuantitySample]) -> Void
    ) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .respiratoryRate) else {
            log("❌ " + NSLocalizedString("respiratory_type_unavailable", comment: ""))
            completion([])
            return
        }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let endDate = Date()

        let predicate = HKQuery.predicateForSamples(withStart: start, end: endDate, options: [])
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(
            sampleType: type,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sort]
        ) { _, results, error in
            guard let samples = results as? [HKQuantitySample], error == nil else {
                log("❌ " + String(format: NSLocalizedString("respiratory_fetch_failed", comment: ""), error?.localizedDescription ?? "Unknown error"))
                completion([])
                return
            }

            log("🫁 " + String(format: NSLocalizedString("respiratory_samples_fetched", comment: ""), samples.count))
            completion(samples)
        }

        log("🫁 " + String(format: NSLocalizedString("respiratory_querying", comment: ""), start.formatted()))
        healthStore.execute(query)
    }

    func uploadSamples(
        _ samples: [HKQuantitySample],
        userId: String,
        progress: @escaping (Int, Int) -> Void,
        log: @escaping (String) -> Void,
        completion: @escaping (Int) -> Void
    ) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let unit = HKUnit(from: "count/min")
        var grouped: [String: [Double]] = [:]

        for sample in samples {
            if manager?.isCancelled == true { break }

            let value = sample.quantity.doubleValue(for: unit)
            let dateKey = formatter.string(from: sample.startDate)
            grouped[dateKey, default: []].append(value)
        }

        let total = grouped.count
        var uploaded = 0
        let group = DispatchGroup()
        var latestDate: Date?

        // ✅ Initial inline log line
        log("🫁 " + String(format: NSLocalizedString("respiratory_upload_progress", comment: ""), uploaded, total))

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
                "brpmAvg": roundedAvg,
                "brpmMin": roundedMin,
                "brpmMax": roundedMax,
                "type": typeIdentifier
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
                        log("❌ " + String(format: NSLocalizedString("respiratory_upload_failed", comment: ""), dateKey, error.localizedDescription))
                    } else {
                        uploaded += 1
                        progress(uploaded, total)

                        // ✅ Inline log update
                        log("🫁 " + String(format: NSLocalizedString("respiratory_upload_progress", comment: ""), uploaded, total))
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
