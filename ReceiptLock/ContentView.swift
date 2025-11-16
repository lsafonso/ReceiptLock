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
                    Group {
                        if selectedTab == 0 {
                            NavigationStack {
                                DashboardView()
                            }
                        } else if selectedTab == 1 {
                            ApplianceListView()
                        } else if selectedTab == 2 {
                            AddApplianceView()
                        } else if selectedTab == 3 {
                            RemindersTabView()
                        } else if selectedTab == 4 {
                            SettingsView()
                        }
                    }
                    .animation(.easeInOut, value: selectedTab)
                    
                    // Custom tab bar
                    VStack {
                        Spacer()
                        customTabBar
                    }
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                }
                .background(AppTheme.background)
                .onAppear {
                    setupTabBarAppearance()
                }
                .onReceive(NotificationCenter.default.publisher(for: switchToAppliancesTabNotification)) { _ in
                    selectedTab = 1 // Switch to Items tab (now at index 1)
                }
            }
        }
    }
    
    // MARK: - Custom Tab Bar
    private var customTabBar: some View {
        VStack(spacing: 0) {
            // 1px top separator edge-to-edge
            Rectangle()
                .fill(AppTheme.separator)
                .frame(height: 1)
            
            HStack(spacing: 0) {
                // Home Tab
                tabButton(
                    icon: "house.fill",
                    title: "Home",
                    isSelected: selectedTab == 0,
                    action: { selectedTab = 0 }
                )
                
                // Items Tab
                tabButton(
                    icon: "list.bullet",
                    title: "Items",
                    isSelected: selectedTab == 1,
                    action: { selectedTab = 1 }
                )
                
                // Add Tab (Special styling) - CENTER POSITION
                scanTabButton
                
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
            .padding(.horizontal, 0)
            .padding(.top, 4) // Reduced internal top padding
            .padding(.bottom, 0)
            .frame(height: 50) // Total height 50pt (will be 52pt with separator + safe area)
        }
        .background(AppTheme.background) // Same as page background
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 0)
        }
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
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? AppTheme.primary : AppTheme.inactiveTabColor)
                    .frame(width: 44, height: 44) // Icon container ≈ 44×44
                
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? AppTheme.primary : AppTheme.inactiveTabColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                    .layoutPriority(1)
            }
        }
        .frame(maxWidth: .infinity) // Equal spacing for each tab
    }
    
    private var scanTabButton: some View {
        Button(action: { selectedTab = 2 }) {
            VStack(spacing: 4) {
                if selectedTab == 2 {
                    // Active state: white icon on brand green background
                    ZStack {
                        Circle()
                            .fill(AppTheme.primary)
                            .frame(width: 28, height: 28) // Icon circle size
                        
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 20, weight: .medium)) // Consistent icon size
                            .foregroundColor(.white)
                    }
                    .frame(width: 44, height: 44) // Icon container ≈ 44×44 (same as others)
                    
                    Text("Add")
                        .font(.system(size: 10, weight: .medium)) // Consistent label font/size
                        .foregroundColor(AppTheme.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                        .layoutPriority(1)
                } else {
                    // Inactive state: inactive color icon
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 20, weight: .medium)) // Consistent icon size
                        .foregroundColor(AppTheme.inactiveTabColor)
                        .frame(width: 44, height: 44) // Icon container ≈ 44×44 (same as others)
                    
                    Text("Add")
                        .font(.system(size: 10, weight: .medium)) // Consistent label font/size
                        .foregroundColor(AppTheme.inactiveTabColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                        .layoutPriority(1)
                }
            }
        }
        .frame(maxWidth: .infinity) // Equal spacing (same horizontal footprint as others)
    }
    
    private func setupTabBarAppearance() {
        // This is now handled by our custom tab bar
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
