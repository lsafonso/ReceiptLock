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
    
    // Notification name for switching tabs
    private let switchToAppliancesTabNotification = Notification.Name("switchToAppliancesTab")
    
    var body: some View {
        Group {
            if !profileManager.hasCompletedOnboarding {
                OnboardingView()
            } else {
                ZStack {
                    // Main content
                    TabView(selection: $selectedTab) {
                        DashboardView()
                            .tag(0)
                        
                        AddApplianceView()
                            .tag(1)
                        
                        ApplianceListView()
                            .tag(2)
                        
                        RemindersTabView()
                            .tag(3)
                        
                        SettingsView()
                            .tag(4)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut, value: selectedTab)
                    
                    // Custom tab bar
                    VStack {
                        Spacer()
                        customTabBar
                    }
                }
                .background(AppTheme.background)
                .onAppear {
                    setupTabBarAppearance()
                }
                .onReceive(NotificationCenter.default.publisher(for: switchToAppliancesTabNotification)) { _ in
                    selectedTab = 2 // Switch to Appliances tab (now at index 2)
                }
            }
        }
    }
    
    // MARK: - Custom Tab Bar
    private var customTabBar: some View {
        HStack(spacing: 0) {
            // Home Tab
            tabButton(
                icon: "house.fill",
                title: "Home",
                isSelected: selectedTab == 0,
                action: { selectedTab = 0 }
            )
            
            // Add Tab (Special styling)
            addTabButton
                .onTapGesture {
                    selectedTab = 1
                }
            
            // Appliances Tab
            tabButton(
                icon: "list.bullet",
                title: "Appliances",
                isSelected: selectedTab == 2,
                action: { selectedTab = 2 }
            )
            
            // Reminders Tab
            tabButton(
                icon: "bell.fill",
                title: "Reminders",
                isSelected: selectedTab == 3,
                action: { selectedTab = 3 }
            )
            
            // Settings Tab
            tabButton(
                icon: "gearshape.fill",
                title: "Settings",
                isSelected: selectedTab == 4,
                action: { selectedTab = 4 }
            )
        }
        .padding(.horizontal, AppTheme.spacing)
        .padding(.bottom, 34) // Account for safe area
        .background(AppTheme.cardBackground)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
    }
    
    private func tabButton(
        icon: String,
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? AppTheme.primary : AppTheme.secondaryText)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(isSelected ? AppTheme.primary : AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
    
    private var addTabButton: some View {
        Button(action: { selectedTab = 1 }) {
            VStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.title.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(AppTheme.primary)
                    .clipShape(Circle())
                
                Text("Add")
                    .font(.caption2)
                    .foregroundColor(AppTheme.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
    
    private func setupTabBarAppearance() {
        // This is now handled by our custom tab bar
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
