//
//  EmptyStateView.swift
//  PulmoPulse
//
//  Created by Wolfgang Kleinhaentz on 30/06/2025.
//

import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "doc.text.magnifyingglass")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.gray)

                Text(NSLocalizedString("no_questionnaires_title", comment: ""))
                    .font(.title2)
                    .foregroundColor(.red)

                Text(NSLocalizedString("no_questionnaires_subtitle", comment: ""))
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

