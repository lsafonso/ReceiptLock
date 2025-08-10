//
//  ContentView.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab = 0
    @StateObject private var profileManager = UserProfileManager.shared
    
    var body: some View {
        Group {
            if !profileManager.hasCompletedOnboarding {
                OnboardingView()
            } else {
                TabView(selection: $selectedTab) {
                    DashboardView()
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                        .tag(0)
                    
                    ApplianceListView()
                        .tabItem {
                            Label("Appliances", systemImage: "list.bullet")
                        }
                        .tag(1)
                    
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                        .tag(2)
                }
                .tint(AppTheme.primary)
                .background(AppTheme.background)
                .onAppear {
                    setupTabBarAppearance()
                }
            }
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppTheme.cardBackground)
        
        // Tab bar item appearance
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(AppTheme.secondaryText)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(AppTheme.secondaryText)
        ]
        
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppTheme.primary)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(AppTheme.primary)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
