//
//  HomeView.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 30/06/2025.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var patientStore: PatientStore
    @State private var showingAddSheet = false
    @State private var showingDataTransferSheet = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                QuestionnaireListView()
                Spacer()
            }
            .navigationTitle(NSLocalizedString("questionnaires_title", comment: "Title for the list of questionnaires"))
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape")
                    }

                    Button(action: {
                        showingDataTransferSheet = true
                    }) {
                        Image(systemName: "arrow.up.doc")
                    }

                    Button(action: {
                        showingAddSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .tint(.red)
        .sheet(isPresented: $showingAddSheet) {
            AddQuestionnaireView()
        }
        .sheet(isPresented: $showingDataTransferSheet) {
            DataTransferView()
                .environmentObject(patientStore)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(patientStore)
        }
    }
}

