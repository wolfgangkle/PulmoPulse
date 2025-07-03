//
//  DataUploader.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 01/07/2025.
//

import Foundation
import HealthKit
import FirebaseFirestore

class DataUploader {
    static let uploaders: [HealthDataUploader] = [
        HeartRateUploader(
            dataTypes: [HKObjectType.quantityType(forIdentifier: .heartRate)!],
            healthStore: HealthDataManager.shared.healthStore,
            db: Firestore.firestore(),
            manager: HealthDataManager.shared
        ),
        OxygenSaturationUploader(
            healthStore: HealthDataManager.shared.healthStore,
            db: Firestore.firestore(),
            manager: HealthDataManager.shared
        ),
        StepsUploader(
            dataTypes: [HKObjectType.quantityType(forIdentifier: .stepCount)!],
            healthStore: HealthDataManager.shared.healthStore,
            db: Firestore.firestore(),
            manager: HealthDataManager.shared
        ),
        SleepUploader(
            dataTypes: [HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!],
            healthStore: HealthDataManager.shared.healthStore,
            db: Firestore.firestore(),
            manager: HealthDataManager.shared
        ),
        ActivityUploader(
            dataTypes: [HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!],
            healthStore: HealthDataManager.shared.healthStore,
            db: Firestore.firestore(),
            manager: HealthDataManager.shared
        ),
        RespiratoryRateUploader(
            dataTypes: [HKObjectType.quantityType(forIdentifier: .respiratoryRate)!],
            healthStore: HealthDataManager.shared.healthStore,
            db: Firestore.firestore(),
            manager: HealthDataManager.shared
        ),
        BodyWeightUploader(
            dataTypes: [HKObjectType.quantityType(forIdentifier: .bodyMass)!],
            healthStore: HealthDataManager.shared.healthStore,
            db: Firestore.firestore(),
            manager: HealthDataManager.shared
        )
    ]

    static func uploadAll(
        questionnaireStore: QuestionnaireStore,
        patientStore: PatientStore,
        progressHandler: @escaping (Int, Int) -> Void,
        logHandler: @escaping (String) -> Void,
        completion: @escaping (String) -> Void
    ) {
        var questionnaireCount = 0
        var healthDataCount = 0

        logHandler(NSLocalizedString("uploading_metadata_log", comment: ""))
        HealthDataManager.shared.uploadPatientMetadata(
            firstName: patientStore.patient.firstName,
            lastName: patientStore.patient.lastName,
            birthDate: patientStore.patient.birthDate
        )

        logHandler(NSLocalizedString("uploading_questionnaires_log", comment: ""))
        questionnaireStore.uploadAllToFirestore { uploadedCount in
            questionnaireCount = uploadedCount
            logHandler(String(format: NSLocalizedString("uploaded_questionnaires_log", comment: ""), uploadedCount))

            guard let userId = HealthDataManager.shared.currentUserId else {
                logHandler(NSLocalizedString("no_user_id_log", comment: ""))
                completion(String(format: NSLocalizedString("upload_questionnaires_no_health_log", comment: ""), questionnaireCount))
                return
            }

            uploadNext(
                uploaderIndex: 0,
                totalUploaded: 0,
                userId: userId,
                progressHandler: progressHandler,
                logHandler: logHandler
            ) { totalHealthData in
                healthDataCount = totalHealthData
                let summary = String(format: NSLocalizedString("upload_summary_log", comment: ""), questionnaireCount, healthDataCount)
                logHandler(summary)
                completion(summary)
            }
        }
    }

    private static func uploadNext(
        uploaderIndex: Int,
        totalUploaded: Int,
        userId: String,
        progressHandler: @escaping (Int, Int) -> Void,
        logHandler: @escaping (String) -> Void,
        completion: @escaping (Int) -> Void
    ) {
        if HealthDataManager.shared.isCancelled {
            logHandler(NSLocalizedString("upload_cancelled_log", comment: ""))
            completion(totalUploaded)
            return
        }

        guard uploaderIndex < uploaders.count else {
            completion(totalUploaded)
            return
        }

        let uploader = uploaders[uploaderIndex]

        HealthDataManager.shared.getEffectiveUploadStartDate(
            for: uploader.typeIdentifier,
            userId: userId,
            maxDaysBack: HealthDataManager.shared.dataUploadWindowDays
        ) { startDate in
            uploader.uploadSince(
                startDate: startDate,
                userId: userId,
                progressHandler: progressHandler,
                logHandler: logHandler
            ) { uploadedCount in
                uploadNext(
                    uploaderIndex: uploaderIndex + 1,
                    totalUploaded: totalUploaded + uploadedCount,
                    userId: userId,
                    progressHandler: progressHandler,
                    logHandler: logHandler,
                    completion: completion
                )
            }
        }
    }
}

