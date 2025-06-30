//
//  QuestionnaireListView.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 30/06/2025.
//

import SwiftUI

struct QuestionnaireListView: View {
    @EnvironmentObject var questionnaireStore: QuestionnaireStore

    var body: some View {
        VStack {
            if questionnaireStore.entries.isEmpty {
                EmptyStateView()
            } else {
                List {
                    ForEach(questionnaireStore.entries.sorted(by: { $0.timestamp > $1.timestamp })) { entry in
                        NavigationLink(destination: QuestionnaireDetailView(entry: entry)) {
                            VStack(alignment: .leading) {
                                Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(.headline)

                                ForEach(entry.answers.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                    Text("\(key): \(value.isEmpty ? "(empty)" : value)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.white)
                    }
                    .onDelete(perform: deleteEntry)
                }
                .listStyle(.plain)
                .background(Color.white)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }

    private func deleteEntry(at offsets: IndexSet) {
        let sortedEntries = questionnaireStore.entries.sorted(by: { $0.timestamp > $1.timestamp })
        let entriesToDelete = offsets.map { sortedEntries[$0] }

        for entry in entriesToDelete {
            questionnaireStore.delete(entry)
        }
    }
}

