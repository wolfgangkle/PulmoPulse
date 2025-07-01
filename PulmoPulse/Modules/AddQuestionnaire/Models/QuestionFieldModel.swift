//
//  QuestionFieldModel.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 30/06/2025.
//

import Foundation

enum QuestionType {
    case yesNo
    case rating1to5
    case multipleChoice(options: [String])
    case multiSelect(options: [String])
}

struct QuestionFieldModel: Identifiable {
    let id: String
    let label: String
    let type: QuestionType
}

