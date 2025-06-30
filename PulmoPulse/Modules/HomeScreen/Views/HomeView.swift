//
//  HomeView.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 30/06/2025.
//

import SwiftUI

struct HomeView: View {
    @State private var showingAddSheet = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                QuestionnaireListView()
                Spacer()
            }
            .navigationTitle("Questionnaires")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddSheet = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.red) // 🔴 Make the symbol red
                    }
                }
            }
            .background(Color.white) // make sure background is white
        }
        .sheet(isPresented: $showingAddSheet) {
            AddQuestionnaireView()
        }
    }
}

#Preview {
    HomeView()
}

