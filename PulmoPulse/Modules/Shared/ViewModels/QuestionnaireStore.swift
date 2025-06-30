//
//  QuestionnaireStore.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 30/06/2025.
//

import Foundation
import SwiftUI

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
        load() // re-sync from storage
    }

    func delete(_ entry: QuestionnaireEntry) {
        QuestionnaireStorageManager.delete(entry)
        load()
    }
}
