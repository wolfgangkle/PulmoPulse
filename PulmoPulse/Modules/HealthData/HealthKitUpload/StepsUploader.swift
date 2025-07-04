
//
//  StepsUploader.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 01/07/2025.
//


import Foundation
import HealthKit
import FirebaseFirestore

struct StepsUploader: HealthDataUploader {
    var dataTypes: [HKObjectType]

    let healthStore: HKHealthStore
    let db: Firestore
    weak var manager: HealthDataManager?

    var typeIdentifier: String { "steps" }

    func fetchSamples(
        since startDate: Date,
        log: @escaping (String) -> Void,
        completion: @escaping ([HKQuantitySample]) -> Void
    ) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            log("❌ " + NSLocalizedString("steps_type_unavailable", comment: ""))
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
                log("❌ " + String(format: NSLocalizedString("steps_fetch_error", comment: ""), error?.localizedDescription ?? "Unknown error"))
                completion([])
                return
            }

            log("👟 " + String(format: NSLocalizedString("steps_samples_fetched", comment: ""), samples.count))
            completion(samples)
        }

        log("👟 " + String(format: NSLocalizedString("steps_querying", comment: ""), start.formatted()))
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

        var grouped: [String: [Double]] = [:]

        for sample in samples {
            if manager?.isCancelled == true { break }

            let count = sample.quantity.doubleValue(for: .count())
            let dateKey = formatter.string(from: sample.startDate)
            grouped[dateKey, default: []].append(count)
        }

        let total = grouped.count
        var uploaded = 0
        let group = DispatchGroup()
        var latestDate: Date?

        // ✅ Inline log at start
        log("👟 " + String(format: NSLocalizedString("steps_upload_progress", comment: ""), uploaded, total))

        for (dateKey, values) in grouped {
            guard !values.isEmpty else { continue }

            let sum = values.reduce(0, +)
            let steps = Int(sum)

            let date = formatter.date(from: dateKey) ?? Date()
            latestDate = max(latestDate ?? date, date)

            let data: [String: Any] = [
                "date": Timestamp(date: date),
                "steps": steps,
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
                        log("❌ " + String(format: NSLocalizedString("steps_upload_error", comment: ""), dateKey, error.localizedDescription))
                    } else {
                        uploaded += 1
                        log("👟 " + String(format: NSLocalizedString("steps_upload_progress", comment: ""), uploaded, total))
                        progress(uploaded, total)
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
