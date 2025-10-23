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
                        
                        ApplianceListView()
                            .tag(1)
                        
                        AddApplianceView()
                            .tag(2)
                        
                        RemindersTabView()
                            .tag(3)
                        
                        SettingsView()
                            .tag(4)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut, value: selectedTab)
                    .padding(.bottom, 100) // Add bottom padding to account for tab bar
                    
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
                    selectedTab = 1 // Switch to Appliances tab (now at index 1)
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
            
            // Appliances Tab
            tabButton(
                icon: "list.bullet",
                title: "Appliances",
                isSelected: selectedTab == 1,
                action: { selectedTab = 1 }
            )
            
            // Scan Tab (Special styling) - CENTER POSITION
            scanTabButton
                .onTapGesture {
                    selectedTab = 2
                }
            
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
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 0)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(AppTheme.cardBackground)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: -4)
        )
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
                    .foregroundColor(isSelected ? AppTheme.primary : Color(red: 0.4, green: 0.4, blue: 0.4))
                
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? AppTheme.primary : Color(red: 0.4, green: 0.4, blue: 0.4))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
    
    private var scanTabButton: some View {
        Button(action: { selectedTab = 2 }) {
            VStack(spacing: 4) {
                ZStack {
                    if selectedTab == 2 {
                        // Active state: white icon on blue background
                        Circle()
                            .fill(AppTheme.primary)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    } else {
                        // Inactive state: gray outline icon
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                    }
                }
                
                // No text label for scan button when active, show "Scan" when inactive
                if selectedTab != 2 {
                    Text("Scan")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                }
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
