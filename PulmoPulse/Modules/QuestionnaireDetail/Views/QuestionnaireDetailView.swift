
//
//  QuestionnaireDetailView.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 30/06/2025.
//

import SwiftUI

struct QuestionnaireDetailView: View {
    let entry: QuestionnaireEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Submitted on")
                .font(.caption)
                .foregroundColor(.gray)

            Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                .font(.title3)
                .bold()

            Divider()

            ForEach(entry.answers.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                let label = defaultQuestionnaireSchema.first(where: { $0.id == key })?.label ?? key

                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .font(.headline)
                    Text(value.isEmpty ? "(No response)" : value)
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                Divider()
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Details")
        .background(Color.white)
    }
}
