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
        let startMessage = String(format: NSLocalizedString("upload_started", comment: ""), typeIdentifier)
        logHandler("📡 \(startMessage)")

        fetchSamples(since: startDate, log: logHandler) { samples in
            let fetchedMessage = String(format: NSLocalizedString("samples_fetched", comment: ""), samples.count, typeIdentifier)
            logHandler("📊 \(fetchedMessage)")

            if samples.isEmpty {
                let noSamplesMessage = String(format: NSLocalizedString("no_samples_found", comment: ""), typeIdentifier)
                logHandler("⚠️ \(noSamplesMessage)")
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

