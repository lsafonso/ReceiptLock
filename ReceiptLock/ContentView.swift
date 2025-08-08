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
    @State private var showingAddAppliance = false
    
    var body: some View {
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
            
            // Add button - this will be a placeholder that shows the add sheet
            Color.clear
                .tabItem {
                    Label("Add", systemImage: "plus.circle.fill")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .tint(AppTheme.primary)
        .background(AppTheme.background)
        .onAppear {
            setupTabBarAppearance()
        }
        .onChange(of: selectedTab) { _, newValue in
            if newValue == 2 {
                showingAddAppliance = true
                selectedTab = 0 // Reset to home tab
            }
        }
        .sheet(isPresented: $showingAddAppliance) {
            AddApplianceView()
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
