//
//  ProfileView.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject private var profileManager = UserProfileManager.shared
    @State private var showingProfileEdit = false
    @State private var showingOnboardingReset = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.largeSpacing) {
                    // Profile Header
                    profileHeader
                    
                    // Settings Sections
                    settingsSections
                    
                    // App Info
                    appInfoSection
                }
                .padding(AppTheme.spacing)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingProfileEdit) {
            ProfileEditView()
        }
        .alert("Reset Onboarding", isPresented: $showingOnboardingReset) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                profileManager.resetOnboarding()
            }
        } message: {
            Text("This will show the onboarding flow again on next app launch.")
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: AppTheme.spacing) {
            AvatarView(
                image: profileManager.getAvatarImage(),
                size: 80,
                showBorder: true
            )
            
            VStack(spacing: AppTheme.smallSpacing) {
                Text(profileManager.currentProfile.name.isEmpty ? "User" : profileManager.currentProfile.name)
                    .font(.title2.weight(.semibold))
                    .foregroundColor(AppTheme.text)
                
                Text("Appliance Warranty Tracker")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            Button("Edit Profile") {
                showingProfileEdit = true
            }
            .secondaryButton()
        }
        .padding(AppTheme.largeSpacing)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var settingsSections: some View {
        VStack(spacing: AppTheme.spacing) {
            // Preferences Section
            VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
                Text("Preferences")
                    .font(.headline)
                    .foregroundColor(AppTheme.text)
                
                VStack(spacing: AppTheme.smallSpacing) {
                    HStack {
                        Text("Active Reminders")
                        Spacer()
                        Text("\(ReminderManager.shared.preferences.enabledReminders.count) configured")
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(AppTheme.cornerRadius)
                    
                    HStack {
                        Text("Theme")
                        Spacer()
                        Text(profileManager.currentProfile.preferences.theme.displayName)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(AppTheme.cornerRadius)
                }
            }
            
            // App Settings Section
            VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
                Text("App Settings")
                    .font(.headline)
                    .foregroundColor(AppTheme.text)
                
                VStack(spacing: AppTheme.smallSpacing) {
                    Button("Reset Onboarding") {
                        showingOnboardingReset = true
                    }
                    .foregroundColor(AppTheme.warning)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(AppTheme.cornerRadius)
                }
            }
        }
    }
    
    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
            Text("App Information")
                .font(.headline)
                .foregroundColor(AppTheme.text)
            
            VStack(spacing: AppTheme.smallSpacing) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(AppTheme.secondaryText)
                }
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.cornerRadius)
                
                HStack {
                    Text("Build")
                    Spacer()
                    Text("1")
                        .foregroundColor(AppTheme.secondaryText)
                }
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.cornerRadius)
            }
        }
    }
}

#Preview {
    ProfileView()
}
