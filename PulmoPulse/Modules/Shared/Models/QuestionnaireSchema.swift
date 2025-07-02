//
//  QuestionnaireSchema.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 30/06/2025.
//

import Foundation

let defaultQuestionnaireSchema: [QuestionFieldModel] = [
    QuestionFieldModel(id: "meds", label: NSLocalizedString("did_you_take_your_medication", comment: ""), type: .yesNo),
    QuestionFieldModel(id: "therapy", label: NSLocalizedString("did_you_do_airway_clearance", comment: ""), type: .yesNo),
    QuestionFieldModel(id: "inhaler", label: NSLocalizedString("did_you_use_inhaler", comment: ""), type: .yesNo),
    QuestionFieldModel(id: "feel", label: NSLocalizedString("how_do_you_feel_today", comment: ""), type: .rating1to5),
    QuestionFieldModel(id: "sleep", label: NSLocalizedString("how_well_did_you_sleep", comment: ""), type: .rating1to5),
    QuestionFieldModel(id: "breath", label: NSLocalizedString("did_you_experience_breathlessness", comment: ""), type: .multipleChoice(options: [
        NSLocalizedString("none", comment: ""),
        NSLocalizedString("mild", comment: ""),
        NSLocalizedString("moderate", comment: ""),
        NSLocalizedString("severe", comment: "")
    ])),
    QuestionFieldModel(id: "cough", label: NSLocalizedString("did_you_cough_more", comment: ""), type: .multipleChoice(options: [
        NSLocalizedString("yes", comment: ""),
        NSLocalizedString("no", comment: ""),
        NSLocalizedString("not_sure", comment: "")
    ])),
    QuestionFieldModel(id: "digestion", label: NSLocalizedString("did_you_have_digestive_issues", comment: ""), type: .multipleChoice(options: [
        NSLocalizedString("no", comment: ""),
        NSLocalizedString("mild", comment: ""),
        NSLocalizedString("severe", comment: "")
    ])),
    QuestionFieldModel(id: "appetite", label: NSLocalizedString("how_was_your_appetite", comment: ""), type: .rating1to5),
    QuestionFieldModel(id: "infectionSigns", label: NSLocalizedString("did_you_notice_infection_signs", comment: ""), type: .multiSelect(options: [
        NSLocalizedString("fever", comment: ""),
        NSLocalizedString("increased_mucus", comment: ""),
        NSLocalizedString("change_mucus_color", comment: ""),
        NSLocalizedString("chest_pain", comment: ""),
        NSLocalizedString("none_of_the_above", comment: "")
    ])),
    QuestionFieldModel(id: "exercise", label: NSLocalizedString("did_you_exercise_today", comment: ""), type: .yesNo),
    QuestionFieldModel(id: "hydration", label: NSLocalizedString("did_you_stay_hydrated", comment: ""), type: .multipleChoice(options: [
        NSLocalizedString("yes", comment: ""),
        NSLocalizedString("no", comment: ""),
        NSLocalizedString("not_sure", comment: "")
    ]))
]

