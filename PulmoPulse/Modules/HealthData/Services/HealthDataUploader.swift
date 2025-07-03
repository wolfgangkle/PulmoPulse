//
//  HealthDataUploader.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 01/07/2025.
//

import Foundation
import HealthKit
import FirebaseFirestore

protocol HealthDataUploader {
    var typeIdentifier: String { get }
    var dataTypes: [HKObjectType] { get }
    var healthStore: HKHealthStore { get }
    var db: Firestore { get }
    var manager: HealthDataManager? { get }

    func fetchSamples(
        since startDate: Date,
        log: @escaping (String) -> Void,
        completion: @escaping ([HKQuantitySample]) -> Void
    )

    func uploadSamples(
        _ samples: [HKQuantitySample],
        userId: String,
        progress: @escaping (Int, Int) -> Void,
        log: @escaping (String) -> Void,
        completion: @escaping (Int) -> Void
    )
}

extension HealthDataUploader {
    func uploadSince(
        startDate: Date,
        userId: String,
        progressHandler: @escaping (Int, Int) -> Void,
        logHandler: @escaping (String) -> Void,
        completion: @escaping (Int) -> Void
    ) {
        let name = typeIdentifier // or replace with displayName if you add that later

        if HealthDataManager.shared.isCancelled {
            let cancelledMessage = NSLocalizedString("upload_cancelled_log", comment: "Upload cancelled")
            logHandler("❌ \(cancelledMessage)")
            completion(0)
            return
        }

        let startMessageTemplate = NSLocalizedString("upload_started", comment: "Upload start")
        logHandler("📡 " + String(format: startMessageTemplate, name))

        let fetchStart = Date()

        fetchSamples(since: startDate, log: logHandler) { samples in
            let duration = Date().timeIntervalSince(fetchStart)

            let fetchedMessageTemplate = NSLocalizedString("samples_fetched", comment: "Samples fetched")
            logHandler("📊 " + String(format: fetchedMessageTemplate, samples.count, name))

            let fetchDurationMessage = NSLocalizedString("fetch_duration_log", comment: "Fetch duration")
            logHandler("⏱ " + String(format: fetchDurationMessage, duration))

            if samples.isEmpty {
                let noSamplesMessageTemplate = NSLocalizedString("no_samples_found", comment: "No samples found")
                logHandler("⚠️ " + String(format: noSamplesMessageTemplate, name))
                completion(0)
            } else {
                self.uploadSamples(
                    samples,
                    userId: userId,
                    progress: progressHandler,
                    log: logHandler,
                    completion: completion
                )
            }
        }
    }
}


