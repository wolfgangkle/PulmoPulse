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
                        NavigationLink {
                            QuestionnaireEditView(originalEntry: entry)
                                .environmentObject(questionnaireStore)
                        } label: {
                            Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.headline)
                                .padding(.vertical, 8)
                        }
                    }
                    .onDelete(perform: deleteEntry)
                }
                .listStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func deleteEntry(at offsets: IndexSet) {
        let sortedEntries = questionnaireStore.entries.sorted(by: { $0.timestamp > $1.timestamp })
        let entriesToDelete = offsets.map { sortedEntries[$0] }

        for entry in entriesToDelete {
            questionnaireStore.delete(entry)
        }
    }
}

