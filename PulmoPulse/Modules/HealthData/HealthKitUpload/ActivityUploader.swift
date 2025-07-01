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

    func fetchSamples(
        since _: Date,
        log: @escaping (String) -> Void,
        completion: @escaping ([HKQuantitySample]) -> Void
    ) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            log("❌ " + NSLocalizedString("activity_type_missing", comment: ""))
            completion([])
            return
        }

        let calendar = Calendar.current
        let fallbackStart = calendar.date(byAdding: .day, value: -7, to: Date())!
        let startDate = calendar.startOfDay(for: manager?.getOverrideStartDate() ?? fallbackStart)
        let endDate = Date()

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(
            sampleType: type,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { _, results, error in
            guard let samples = results as? [HKQuantitySample], error == nil else {
                log("❌ " + String(format: NSLocalizedString("activity_fetch_failed", comment: ""), error?.localizedDescription ?? "Unknown error"))
                completion([])
                return
            }

            log("📦 " + String(format: NSLocalizedString("activity_fetched", comment: ""), samples.count))
            completion(samples)
        }

        log("🔥 " + String(format: NSLocalizedString("activity_querying_from", comment: ""), startDate.formatted(date: .abbreviated, time: .omitted)))
        healthStore.execute(query)
    }

    func uploadSamples(
        _ samples: [HKQuantitySample],
        userId: String,
        progress: @escaping (Int, Int) -> Void,
        log: @escaping (String) -> Void,
        completion: @escaping (Int) -> Void
    ) {
        let kcalUnit = HKUnit.kilocalorie()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var grouped: [String: [Double]] = [:]

        for sample in samples {
            if manager?.isCancelled == true { break }
            let value = sample.quantity.doubleValue(for: kcalUnit)
            let dateKey = formatter.string(from: sample.startDate)
            grouped[dateKey, default: []].append(value)
        }

        var uploaded = 0
        let group = DispatchGroup()
        var latestDate: Date?

        for (dateKey, values) in grouped {
            guard !values.isEmpty else { continue }

            let total = values.reduce(0, +)
            let roundedTotal = Int(total)

            let date = formatter.date(from: dateKey) ?? Date()
            latestDate = max(latestDate ?? date, date)

            let data: [String: Any] = [
                "date": Timestamp(date: date),
                "kcal": roundedTotal,
                "type": typeIdentifier
            ]

            group.enter()
            db.collection("patients")
                .document(userId)
                .collection("healthData")
                .document("activity")
                .collection("daily")
                .document(dateKey)
                .setData(data) { error in
                    if let error = error {
                        log("❌ " + String(format: NSLocalizedString("activity_upload_failed", comment: ""), dateKey, error.localizedDescription))
                    } else {
                        uploaded += 1
                        log("✅ " + String(format: NSLocalizedString("activity_uploaded", comment: ""), dateKey, roundedTotal))
                        progress(uploaded, grouped.count)
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
