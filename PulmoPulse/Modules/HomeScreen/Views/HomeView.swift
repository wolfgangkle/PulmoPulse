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
            VStack {
                QuestionnaireListView() // <-- this will show the saved list
                Spacer()
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddQuestionnaireView() // <-- we’ll build this next
        }
    }
}

#Preview {
    HomeView()
}

