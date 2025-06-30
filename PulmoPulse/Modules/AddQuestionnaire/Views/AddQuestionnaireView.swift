//
//  AddQuestionnaireView.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 30/06/2025.
//



import SwiftUI

struct AddQuestionnaireView: View {
    @Environment(\.dismiss) var dismiss

    @State private var answers: [String: String] = [:]

    // Placeholder questions (easy to update later)
    let questions: [QuestionFieldModel] = [
        QuestionFieldModel(id: "q1", label: "How do you feel today?"),
        QuestionFieldModel(id: "q2", label: "Any shortness of breath?"),
        QuestionFieldModel(id: "q3", label: "Sleep quality last night?")
    ]

    var body: some View {
        NavigationView {
            Form {
                ForEach(questions) { question in
                    Section(header: Text(question.label)) {
                        TextField("Your answer...", text: Binding(
                            get: { answers[question.id] ?? "" },
                            set: { answers[question.id] = $0 }
                        ))
                    }
                }
            }
            .navigationTitle("New Questionnaire")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveQuestionnaire()
                        dismiss()
                    }
                }
            }
        }
    }

    private func saveQuestionnaire() {
        let entry = QuestionnaireEntry(
            id: UUID(),
            timestamp: Date(),
            answers: answers
        )
        QuestionnaireStorageManager.save(entry)
    }

}
