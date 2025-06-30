//
//  QuestionnaireStorageManager.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 30/06/2025.
//

import Foundation

struct QuestionnaireStorageManager {
    static private let storageKey = "saved_questionnaires"

    static func save(_ entry: QuestionnaireEntry) {
        var current = loadAll()
        current.append(entry)
        if let encoded = try? JSONEncoder().encode(current) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    static func loadAll() -> [QuestionnaireEntry] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([QuestionnaireEntry].self, from: data) else {
            return []
        }
        return decoded
    }

    static func clearAll() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
    
    static func delete(_ entry: QuestionnaireEntry) {
        var current = loadAll()
        current.removeAll { $0.id == entry.id }
        if let encoded = try? JSONEncoder().encode(current) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

}
