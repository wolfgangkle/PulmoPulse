
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

    let questions: [QuestionFieldModel] = defaultQuestionnaireSchema

    var body: some View {
        NavigationStack {
            List {
                ForEach(questions) { question in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(question.label)
                            .font(.headline)

                        if case .rating1to5 = question.type {
                            Text("rating_scale_hint".localized)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        answerButtons(for: question)
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(.plain)
            .navigationTitle("new_questionnaire_title".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel_button".localized) {
                        dismiss()
                    }
                    .foregroundColor(.red)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("save_button".localized) {
                        saveQuestionnaire()
                        dismiss()
                    }
                    .foregroundColor(.red)
                    .disabled(answers.count < questions.count)
                }
            }
        }
    }

    @ViewBuilder
    private func answerButtons(for question: QuestionFieldModel) -> some View {
        let selected = answers[question.id] ?? ""

        switch question.type {
        case .yesNo:
            buttonRow(options: ["yes".localized, "no".localized], selected: selected) { choice in
                answers[question.id] = choice
            }

        case .rating1to5:
            buttonRow(options: (1...5).map { String($0) }, selected: selected) { choice in
                answers[question.id] = choice
            }

        case .multipleChoice(let options):
            buttonRow(options: options.map { $0.localized }, selected: selected) { choice in
                answers[question.id] = choice
            }

        case .multiSelect(let options):
            multiSelectRow(questionId: question.id, options: options.map { $0.localized })
        }
    }

    private func buttonRow(options: [String], selected: String, onSelect: @escaping (String) -> Void) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        onSelect(option)
                    }) {
                        Text(option)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .frame(minWidth: 60, minHeight: 44)
                            .padding(.horizontal, 8)
                            .background(selected == option ? Color.red : Color.red.opacity(0.4))
                            .cornerRadius(8)
                    }
                }
            }
        }
    }

    private func multiSelectRow(questionId: String, options: [String]) -> some View {
        let selectedValues = Set((answers[questionId] ?? "").components(separatedBy: ",").filter { !$0.isEmpty })

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    let isSelected = selectedValues.contains(option)

                    Button(action: {
                        var newValues = selectedValues
                        if isSelected {
                            newValues.remove(option)
                        } else {
                            newValues.insert(option)
                        }
                        answers[questionId] = newValues.sorted().joined(separator: ",")
                    }) {
                        Text(option)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .frame(minWidth: 60, minHeight: 44)
                            .padding(.horizontal, 8)
                            .background(isSelected ? Color.red : Color.red.opacity(0.4))
                            .cornerRadius(8)
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
        questionnaireStore.add(entry)
    }
}
