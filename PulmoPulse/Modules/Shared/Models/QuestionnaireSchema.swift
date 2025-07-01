//
//  QuestionnaireSchema.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 30/06/2025.
//

import Foundation

let defaultQuestionnaireSchema: [QuestionFieldModel] = [
    QuestionFieldModel(id: "meds", label: "Did you take your medication today?", type: .yesNo),
    QuestionFieldModel(id: "therapy", label: "Did you do your airway clearance therapy today?", type: .yesNo),
    QuestionFieldModel(id: "inhaler", label: "Did you use your inhaler or nebulizer today?", type: .yesNo),
    QuestionFieldModel(id: "feel", label: "How do you feel today?", type: .rating1to5),
    QuestionFieldModel(id: "sleep", label: "How well did you sleep last night?", type: .rating1to5),
    QuestionFieldModel(id: "breath", label: "Did you experience shortness of breath today?", type: .multipleChoice(options: ["None", "Mild", "Moderate", "Severe"])),
    QuestionFieldModel(id: "cough", label: "Did you cough more than usual today?", type: .multipleChoice(options: ["Yes", "No", "Not sure"])),
    QuestionFieldModel(id: "digestion", label: "Did you have any digestive issues today?", type: .multipleChoice(options: ["No", "Mild", "Severe"])),
    QuestionFieldModel(id: "appetite", label: "How was your appetite today?", type: .rating1to5),
    QuestionFieldModel(id: "infectionSigns", label: "Did you notice any of the following?", type: .multiSelect(options: ["Fever", "Increased mucus", "Change in mucus color", "Chest pain", "None of the above"])),
    QuestionFieldModel(id: "exercise", label: "Did you exercise today?", type: .yesNo),
    QuestionFieldModel(id: "hydration", label: "Did you stay hydrated today?", type: .multipleChoice(options: ["Yes", "No", "Not sure"]))
]

