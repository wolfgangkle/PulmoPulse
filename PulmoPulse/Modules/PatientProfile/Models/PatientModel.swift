//
//  PatientModel.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 30/06/2025.
//

import Foundation

struct PatientModel: Codable {
    var firstName: String
    var lastName: String
    var birthDate: Date?

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var birthDateFormatted: String {
        guard let birthDate else { return "" }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: birthDate)
    }
}

