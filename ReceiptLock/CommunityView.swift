//
//  CommunityView.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI

struct CommunityView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()
                
                VStack(spacing: AppTheme.largeSpacing) {
                    Spacer()
                    
                    EmptyStateView(
                        title: "Community Coming Soon",
                        message: "Connect with other appliance owners, share tips, and get warranty advice from the community.",
                        systemImage: "person.3.fill"
                    )
                    
                    Spacer()
                }
                .padding(AppTheme.largeSpacing)
            }
            .navigationTitle("Community")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    CommunityView()
}
