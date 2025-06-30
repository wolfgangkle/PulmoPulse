//
//  QuestionnaireListView.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 30/06/2025.
//

import SwiftUI

struct QuestionnaireListView: View {
    @State private var entries: [QuestionnaireEntry] = []

    var body: some View {
        VStack {
            if entries.isEmpty {
                EmptyStateView()
            } else {
                List {
                    ForEach(entries.sorted(by: { $0.timestamp > $1.timestamp })) { entry in
                        VStack(alignment: .leading) {
                            Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.headline)

                            ForEach(entry.answers.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                Text("\(key): \(value)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteEntry)
                }
            }
        }
        .onAppear {
            entries = QuestionnaireStorageManager.loadAll()
        }
    }

    private func deleteEntry(at offsets: IndexSet) {
        for index in offsets {
            let entry = entries[index]
            QuestionnaireStorageManager.delete(entry)
        }
        entries.remove(atOffsets: offsets)
    }
}

