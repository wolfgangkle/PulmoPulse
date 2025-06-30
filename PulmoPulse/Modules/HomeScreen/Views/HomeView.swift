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

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                QuestionnaireListView()
                Spacer()
            }
            .navigationTitle("Questionnaires")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingDataTransferSheet = true
                    }) {
                        Image(systemName: "arrow.up.doc")
                            .foregroundColor(.red)
                    }

                    Button(action: {
                        showingAddSheet = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.red)
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
    }
}


