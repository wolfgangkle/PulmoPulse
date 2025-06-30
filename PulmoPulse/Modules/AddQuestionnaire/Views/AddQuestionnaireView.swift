//
//  AddQuestionnaireView.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 30/06/2025.
//

import SwiftUI

struct AddQuestionnaireView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var questionnaireStore: QuestionnaireStore

    @State private var answers: [String: String] = [:]

    // Use shared schema from defaultQuestionnaireSchema.swift
    let questions: [QuestionFieldModel] = defaultQuestionnaireSchema

    var body: some View {
        NavigationView {
            List {
                ForEach(questions) { question in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(question.label)
                            .font(.headline)

                        TextField("Your answer...", text: Binding(
                            get: { answers[question.id] ?? "" },
                            set: { answers[question.id] = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(.plain)
            .background(Color.white)
            .navigationTitle("New Questionnaire")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .foregroundColor(.red)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveQuestionnaire()
                        dismiss()
                    } label: {
                        Text("Save")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .background(Color.white)
    }

    private func saveQuestionnaire() {
        let entry = QuestionnaireEntry(
            id: UUID(),
            timestamp: Date(),
            answers: answers
        )
        
        questionnaireStore.add(entry)
    }

}
