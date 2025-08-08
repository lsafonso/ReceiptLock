//
//  ProfileView.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()
                
                VStack(spacing: AppTheme.largeSpacing) {
                    Spacer()
                    
                    EmptyStateView(
                        title: "Profile Coming Soon",
                        message: "Manage your account settings, preferences, and warranty notifications.",
                        systemImage: "person.fill"
                    )
                    
                    Spacer()
                }
                .padding(AppTheme.largeSpacing)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    ProfileView()
}
