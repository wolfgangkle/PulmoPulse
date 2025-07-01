//
//  QuestionnaireStore.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 30/06/2025.
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class QuestionnaireStore: ObservableObject {
    @Published var entries: [QuestionnaireEntry] = []

    init() {
        load()
    }

    func load() {
        entries = QuestionnaireStorageManager.loadAll()
    }

    func add(_ entry: QuestionnaireEntry) {
        QuestionnaireStorageManager.save(entry)
        load()
    }

    func delete(_ entry: QuestionnaireEntry) {
        QuestionnaireStorageManager.delete(entry)
        load()
    }

    /// 🔁 Upload all questionnaires to Firestore and delete locally after success
    func uploadAllToFirestore(completion: @escaping (Int) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ Cannot upload questionnaires – no authenticated user.")
            completion(0)
            return
        }

        let collection = Firestore.firestore()
            .collection("patients")
            .document(userId)
            .collection("questionnaires")

        let entriesToUpload = self.entries
        var uploadCount = 0
        let group = DispatchGroup()

        for entry in entriesToUpload {
            group.enter()

            let dict: [String: Any] = [
                "id": entry.id.uuidString,
                "timestamp": Timestamp(date: entry.timestamp),
                "answers": convertAnswersForFirestore(entry.answers)
            ]

            collection.addDocument(data: dict) { error in
                if let error = error {
                    print("❌ Failed to upload questionnaire: \(error.localizedDescription)")
                } else {
                    QuestionnaireStorageManager.delete(entry)
                    uploadCount += 1
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            self.load() // refresh local list after deletion
            print("📤 Uploaded \(uploadCount) questionnaires to Firestore.")
            completion(uploadCount)
        }
    }

    /// 🔄 Convert local string-based answers to Firestore-typed values
    private func convertAnswersForFirestore(_ answers: [String: String]) -> [String: Any] {
        var result: [String: Any] = [:]

        for (key, value) in answers {
            if let question = defaultQuestionnaireSchema.first(where: { $0.id == key }) {
                switch question.type {
                case .rating1to5:
                    result[key] = Int(value) ?? NSNull()

                case .multiSelect:
                    result[key] = value
                        .components(separatedBy: ",")
                        .map { $0.trimmingCharacters(in: .whitespaces) }

                case .yesNo:
                    result[key] = (value == "Yes")

                default:
                    result[key] = value
                }
            } else {
                result[key] = value
            }
        }

        return result
    }
}

