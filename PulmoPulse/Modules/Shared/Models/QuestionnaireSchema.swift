//
//  QuestionnaireSchema.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 30/06/2025.
//

import Foundation

let defaultQuestionnaireSchema: [QuestionFieldModel] = [
    QuestionFieldModel(id: "meds", label: "did_you_take_your_medication".localized, type: .yesNo),
    QuestionFieldModel(id: "therapy", label: "did_you_do_airway_clearance".localized, type: .yesNo),
    QuestionFieldModel(id: "inhaler", label: "did_you_use_inhaler".localized, type: .yesNo),
    QuestionFieldModel(id: "feel", label: "how_do_you_feel_today".localized, type: .rating1to5),
    QuestionFieldModel(id: "sleep", label: "how_well_did_you_sleep".localized, type: .rating1to5),
    QuestionFieldModel(id: "breath", label: "did_you_experience_breathlessness".localized, type: .multipleChoice(options: [
        "none".localized,
        "mild".localized,
        "moderate".localized,
        "severe".localized
    ])),
    QuestionFieldModel(id: "cough", label: "did_you_cough_more".localized, type: .multipleChoice(options: [
        "yes".localized,
        "no".localized,
        "not_sure".localized
    ])),
    QuestionFieldModel(id: "digestion", label: "did_you_have_digestive_issues".localized, type: .multipleChoice(options: [
        "no".localized,
        "mild".localized,
        "severe".localized
    ])),
    QuestionFieldModel(id: "appetite", label: "how_was_your_appetite".localized, type: .rating1to5),
    QuestionFieldModel(id: "infectionSigns", label: "did_you_notice_infection_signs".localized, type: .multiSelect(options: [
        "fever".localized,
        "increased_mucus".localized,
        "change_mucus_color".localized,
        "chest_pain".localized,
        "none_of_the_above".localized
    ])),
    QuestionFieldModel(id: "exercise", label: "did_you_exercise_today".localized, type: .yesNo),
    QuestionFieldModel(id: "hydration", label: "did_you_stay_hydrated".localized, type: .multipleChoice(options: [
        "yes".localized,
        "no".localized,
        "not_sure".localized
    ]))
]

