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
        NavigationStack {
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
            .toolbarColorScheme(.light, for: .navigationBar)              // ✅ light mode for nav bar
            .toolbarBackground(Color.white, for: .navigationBar)          // ✅ white background
            .toolbarBackground(.visible, for: .navigationBar)             // ✅ make nav bar background visible
            .background(Color.white)                                      // ensures content background is white
        }
        .tint(.red) // 🔴 This line changes the back button and label color!
        .sheet(isPresented: $showingAddSheet) {
            AddQuestionnaireView()
        }
    }
}

#Preview {
    HomeView()
}

