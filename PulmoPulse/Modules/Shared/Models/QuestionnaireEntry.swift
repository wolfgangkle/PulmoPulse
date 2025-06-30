//
//  QuestionnaireEntry.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 30/06/2025.
//

import Foundation

struct QuestionnaireEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let answers: [String: String]
}
