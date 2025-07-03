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

    func fetchSamples(
        since _: Date,
        log: @escaping (String) -> Void,
        completion: @escaping ([HKQuantitySample]) -> Void
    ) {
        // Not used (we work directly with CategorySamples)
        completion([])
    }

    func uploadSamples(
        _ _: [HKQuantitySample],
        userId: String,
        progress: @escaping (Int, Int) -> Void,
        log: @escaping (String) -> Void,
        completion: @escaping (Int) -> Void
    ) {
        guard let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            log("❌ " + NSLocalizedString("sleep_type_unavailable", comment: ""))
            completion(0)
            return
        }

        let calendar = Calendar.current
        let fallbackStart = calendar.date(byAdding: .day, value: -5, to: Date())!
        let startDate = calendar.startOfDay(for: manager?.getOverrideStartDate() ?? fallbackStart)
        let endDate = Date()

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

        let query = HKSampleQuery(
            sampleType: type,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sort]
        ) { _, results, error in
            guard let samples = results as? [HKCategorySample], error == nil else {
                log("❌ " + String(format: NSLocalizedString("sleep_fetch_error", comment: ""), error?.localizedDescription ?? "unknown"))
                completion(0)
                return
            }

            log("😴 " + String(format: NSLocalizedString("sleep_samples_fetched", comment: ""), samples.count))

            var sleepByDay: [String: (asleep: TimeInterval, inBed: TimeInterval, sessions: Int)] = [:]
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"

            for sample in samples {
                if manager?.isCancelled == true { break }

                let start = sample.startDate
                let end = sample.endDate
                let duration = end.timeIntervalSince(start)
                let dayKey = formatter.string(from: calendar.startOfDay(for: start))

                var entry = sleepByDay[dayKey] ?? (asleep: 0, inBed: 0, sessions: 0)

                if sample.value == HKCategoryValueSleepAnalysis.inBed.rawValue {
                    entry.inBed += duration
                } else if sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                          sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                          sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                          sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                    entry.asleep += duration
                }

                entry.sessions += 1
                sleepByDay[dayKey] = entry
            }

            let total = sleepByDay.count
            var uploaded = 0
            var latestDate: Date?
            let group = DispatchGroup()

            // ✅ Inline log at start
            log("🛌 " + String(format: NSLocalizedString("sleep_upload_progress", comment: ""), uploaded, total))

            for (dayKey, entry) in sleepByDay {
                let date = formatter.date(from: dayKey) ?? Date()
                latestDate = max(latestDate ?? date, date)

                let data: [String: Any] = [
                    "date": Timestamp(date: date),
                    "type": typeIdentifier,
                    "asleepMinutes": Int(entry.asleep / 60),
                    "inBedMinutes": Int(entry.inBed / 60),
                    "sleepSessions": entry.sessions
                ]

                group.enter()
                db.collection("patients")
                    .document(userId)
                    .collection("healthData")
                    .document("sleep")
                    .collection("daily")
                    .document(dayKey)
                    .setData(data) { error in
                        if let error = error {
                            log("❌ " + String(format: NSLocalizedString("sleep_upload_error", comment: ""), dayKey, error.localizedDescription))
                        } else {
                            uploaded += 1
                            progress(uploaded, total)

                            // ✅ Inline update log
                            log("🛌 " + String(format: NSLocalizedString("sleep_upload_progress", comment: ""), uploaded, total))
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

        log("🛌 " + String(format: NSLocalizedString("sleep_querying", comment: ""), startDate.formatted()))
        healthStore.execute(query)
    }
}
