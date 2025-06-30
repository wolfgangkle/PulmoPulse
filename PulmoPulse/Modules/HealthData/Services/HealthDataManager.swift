//
//  HealthDataManager.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 30/06/2025.
//

import Foundation
import HealthKit
import FirebaseAuth
import FirebaseFirestore

class HealthDataManager {
    static let shared = HealthDataManager()

    private let healthStore = HKHealthStore()

    // ✅ Lazy access to Firestore AFTER Firebase is configured
    private var db: Firestore {
        Firestore.firestore()
    }

    private let typesToRead: Set = [
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    ]

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }

    func fetchRecentHeartRate(completion: @escaping ([HKQuantitySample]) -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        let now = Date()
        let start = Calendar.current.date(byAdding: .day, value: -1, to: now)!

        let predicate = HKQuery.predicateForSamples(withStart: start, end: now, options: [])
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 100, sortDescriptors: [sort]) { _, results, error in
            guard let samples = results as? [HKQuantitySample], error == nil else {
                print("❌ HeartRate fetch error:", error?.localizedDescription ?? "Unknown")
                completion([])
                return
            }
            completion(samples)
        }

        healthStore.execute(query)
    }

    func uploadHeartRateSamples(_ samples: [HKQuantitySample]) {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let collection = db.collection("patients").document(userId).collection("healthData")

        for sample in samples {
            let bpm = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            let data: [String: Any] = [
                "type": "heartRate",
                "bpm": bpm,
                "start": sample.startDate.timeIntervalSince1970,
                "end": sample.endDate.timeIntervalSince1970,
                "source": sample.sourceRevision.source.name
            ]

            collection.addDocument(data: data)
        }
    }
}

