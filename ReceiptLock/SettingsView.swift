//
//  SettingsView.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("selectedTheme") private var selectedTheme = "system"
    @State private var showingExportSheet = false
    @State private var showingImportPicker = false
    @State private var showingDeleteAlert = false
    @State private var showingReminderManagement = false
    @State private var showingProfileEdit = false
    @State private var showingOnboardingReset = false
    @StateObject private var currencyManager = CurrencyManager.shared
    @StateObject private var profileManager = UserProfileManager.shared
    
    let themes = [
        ("system", "System"),
        ("light", "Light"),
        ("dark", "Dark")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: AppTheme.largeSpacing) {
                    profileSection
                    profilePersonalizationSection
                    receiptApplianceSection
                    notificationsRemindersSection
                    securityPrivacySection
                    backupSyncSection
                    dataManagementSection
                    aboutSupportSection
                }
                .padding(AppTheme.spacing)
            }
            .navigationTitle("Settings")
        }
        .alert("Delete All Data", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("This will permanently delete all receipts and associated files. This action cannot be undone.")
        }
        .alert("Reset Onboarding", isPresented: $showingOnboardingReset) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                profileManager.resetOnboarding()
            }
        } message: {
            Text("This will show the onboarding flow again on next app launch.")
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportView()
        }
        .sheet(isPresented: $showingReminderManagement) {
            ReminderManagementView()
        }
        .sheet(isPresented: $showingProfileEdit) {
            ProfileEditView()
        }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [.zip],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result: result)
        }
    }
    
    // MARK: - Profile Section
    
    private var profileSection: some View {
        SettingsSection(title: "Profile", icon: "person.circle.fill") {
            VStack(spacing: AppTheme.spacing) {
                // Profile Header
                HStack(spacing: AppTheme.spacing) {
                    AvatarView(
                        image: profileManager.getAvatarImage(),
                        size: 60,
                        showBorder: true
                    )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(profileManager.currentProfile.name.isEmpty ? "User" : profileManager.currentProfile.name)
                            .font(.title3.weight(.semibold))
                            .foregroundColor(AppTheme.text)
                        
                        Text("Appliance Warranty Tracker")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    
                    Spacer()
                }
                
                Button("Edit Profile") {
                    showingProfileEdit = true
                }
                .secondaryButton()
            }
        }
    }
    
    // MARK: - Profile & Personalization Section
    
    private var profilePersonalizationSection: some View {
        SettingsSection(title: "Profile & Personalization", icon: "person.badge.plus.fill") {
            SettingsRow(
                title: "Profile Photo & Name",
                subtitle: "Update your avatar and display name",
                icon: "person.crop.circle.fill"
            ) {
                Button("Edit") {
                    showingProfileEdit = true
                }
                .foregroundColor(AppTheme.primary)
            }
            
            SettingsRow(
                title: "Currency Preferences",
                subtitle: "\(currencyManager.currencySymbol) \(currencyManager.currencyName)",
                icon: "creditcard.fill"
            ) {
                Picker("Currency", selection: $currencyManager.currentCurrency) {
                    ForEach(currencyManager.getCurrencyList(), id: \.0) { currency in
                        Text(currency.1).tag(currency.0)
                    }
                }
                .pickerStyle(.menu)
            }
            
            SettingsRow(
                title: "Language/Locale",
                subtitle: "English (US)",
                icon: "globe"
            ) {
                Text("Coming Soon")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            SettingsRow(
                title: "Theme & Appearance",
                subtitle: themes.first { $0.0 == selectedTheme }?.1 ?? "System",
                icon: "moon.fill"
            ) {
                Picker("Theme", selection: $selectedTheme) {
                    ForEach(themes, id: \.0) { theme in
                        Text(theme.1).tag(theme.0)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }
    
    // MARK: - Receipt & Appliance Settings Section
    
    private var receiptApplianceSection: some View {
        SettingsSection(title: "Receipt & Appliance Settings", icon: "doc.text.fill") {
            SettingsRow(
                title: "Default Currency",
                subtitle: "\(currencyManager.currencySymbol) \(currencyManager.currencyName)",
                icon: "dollarsign.circle.fill"
            ) {
                Picker("Default Currency", selection: $currencyManager.currentCurrency) {
                    ForEach(currencyManager.getCurrencyList(), id: \.0) { currency in
                        Text(currency.1).tag(currency.0)
                    }
                }
                .pickerStyle(.menu)
            }
            
            SettingsRow(
                title: "Receipt Categories",
                subtitle: "Manage receipt organization",
                icon: "folder.fill"
            ) {
                Text("Coming Soon")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            SettingsRow(
                title: "Warranty Reminder Defaults",
                subtitle: "Set default reminder periods",
                icon: "bell.badge.fill"
            ) {
                Button("Configure") {
                    showingReminderManagement = true
                }
                .foregroundColor(AppTheme.primary)
            }
            
            SettingsRow(
                title: "Receipt Storage Preferences",
                subtitle: "Manage storage and compression",
                icon: "externaldrive.fill"
            ) {
                Text("Coming Soon")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
    }
    
    // MARK: - Notifications & Reminders Section
    
    private var notificationsRemindersSection: some View {
        SettingsSection(title: "Notifications & Reminders", icon: "bell.fill") {
            SettingsRow(
                title: "Reminder Settings",
                subtitle: "Configure multiple reminders and custom messages",
                icon: "bell.badge.fill"
            ) {
                Button("Configure") {
                    showingReminderManagement = true
                }
                .foregroundColor(AppTheme.primary)
            }
            
            let enabledCount = ReminderManager.shared.preferences.enabledReminders.count
            SettingsRow(
                title: "Active Reminders",
                subtitle: "\(enabledCount) reminders configured",
                icon: "checkmark.circle.fill"
            ) {
                EmptyView()
            }
            
            SettingsRow(
                title: "Notification Preferences",
                subtitle: "Sound, badges, and alert styles",
                icon: "speaker.wave.2.fill"
            ) {
                Text("Coming Soon")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            SettingsRow(
                title: "Custom Reminder Messages",
                subtitle: "Personalize your reminder notifications",
                icon: "text.bubble.fill"
            ) {
                Text("Coming Soon")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
    }
    
    // MARK: - Security & Privacy Section
    
    private var securityPrivacySection: some View {
        SettingsSection(title: "Security & Privacy", icon: "lock.shield.fill") {
            SettingsRow(
                title: "Biometric Authentication",
                subtitle: "Face ID, Touch ID, and passcode",
                icon: "faceid"
            ) {
                NavigationLink("Configure") {
                    SecuritySettingsView()
                }
                .foregroundColor(AppTheme.primary)
            }
            
            SettingsRow(
                title: "Encryption Settings",
                subtitle: "Data encryption and security levels",
                icon: "lock.rotation"
            ) {
                NavigationLink("Configure") {
                    SecuritySettingsView()
                }
                .foregroundColor(AppTheme.primary)
            }
            
            SettingsRow(
                title: "Privacy Controls",
                subtitle: "Manage data sharing and consent",
                icon: "hand.raised.fill"
            ) {
                NavigationLink("Manage") {
                    SecuritySettingsView()
                }
                .foregroundColor(AppTheme.primary)
            }
        }
    }
    
    // MARK: - Backup & Sync Section
    
    private var backupSyncSection: some View {
        SettingsSection(title: "Backup & Sync", icon: "icloud.fill") {
            SettingsRow(
                title: "iCloud Sync",
                subtitle: "Automatically sync across devices",
                icon: "icloud"
            ) {
                Toggle("", isOn: Binding(
                    get: { DataBackupManager.shared.isCloudKitEnabled() },
                    set: { DataBackupManager.shared.setCloudKitEnabled($0) }
                ))
                .labelsHidden()
            }
            
            SettingsRow(
                title: "Backup Settings",
                subtitle: "Manage data backup and restore",
                icon: "externaldrive.fill"
            ) {
                NavigationLink("Configure") {
                    BackupSettingsView()
                }
                .foregroundColor(AppTheme.primary)
            }
            
            if let lastBackup = DataBackupManager.shared.lastBackupDate {
                SettingsRow(
                    title: "Last Backup",
                    subtitle: lastBackup.formatted(date: .abbreviated, time: .shortened),
                    icon: "clock.fill"
                ) {
                    EmptyView()
                }
            }
            
            SettingsRow(
                title: "Import/Export",
                subtitle: "Backup and restore data manually",
                icon: "arrow.triangle.2.circlepath"
            ) {
                HStack(spacing: AppTheme.smallSpacing) {
                    Button("Export") {
                        showingExportSheet = true
                    }
                    .foregroundColor(AppTheme.primary)
                    
                    Button("Import") {
                        showingImportPicker = true
                    }
                    .foregroundColor(AppTheme.primary)
                }
            }
        }
    }
    
    // MARK: - Data Management Section
    
    private var dataManagementSection: some View {
        SettingsSection(title: "Data Management", icon: "folder.fill") {
            SettingsRow(
                title: "Storage Usage",
                subtitle: "View app storage and cleanup options",
                icon: "chart.pie.fill"
            ) {
                Text("Coming Soon")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            SettingsRow(
                title: "Data Export",
                subtitle: "Export all receipts and files",
                icon: "square.and.arrow.up.fill"
            ) {
                Button("Export") {
                    showingExportSheet = true
                }
                .foregroundColor(AppTheme.primary)
            }
            
            SettingsRow(
                title: "Data Deletion",
                subtitle: "Permanently remove all data",
                icon: "trash.fill"
            ) {
                Button("Delete") {
                    showingDeleteAlert = true
                }
                .foregroundColor(AppTheme.error)
            }
        }
    }
    
    // MARK: - About & Support Section
    
    private var aboutSupportSection: some View {
        SettingsSection(title: "About & Support", icon: "info.circle.fill") {
            SettingsRow(
                title: "App Version",
                subtitle: "1.0.0",
                icon: "app.badge.fill"
            ) {
                EmptyView()
            }
            
            SettingsRow(
                title: "Build",
                subtitle: "1",
                icon: "hammer.fill"
            ) {
                EmptyView()
            }
            
            SettingsRow(
                title: "Terms & Privacy",
                subtitle: "Read our terms and privacy policy",
                icon: "doc.text.fill"
            ) {
                Text("Coming Soon")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            SettingsRow(
                title: "Support & Feedback",
                subtitle: "Get help and send feedback",
                icon: "questionmark.circle.fill"
            ) {
                Text("Coming Soon")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            SettingsRow(
                title: "Reset Onboarding",
                subtitle: "Show onboarding flow again",
                icon: "arrow.clockwise"
            ) {
                Button("Reset") {
                    showingOnboardingReset = true
                }
                .foregroundColor(AppTheme.warning)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func deleteAllData() {
        // Implementation for deleting all data
        print("Deleting all data...")
    }
    
    private func handleImport(result: Result<[URL], Error>) {
        // Implementation for handling import
        print("Handling import...")
    }
}

// MARK: - Settings Section Component
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.primary)
                    .font(.title2)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppTheme.text)
                
                Spacer()
            }
            
            VStack(spacing: AppTheme.smallSpacing) {
                content
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadius)
    }
}

// MARK: - Settings Row Component
struct SettingsRow<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let content: Content
    
    init(title: String, subtitle: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AppTheme.secondaryText)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(AppTheme.text)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            Spacer()
            
            content
        }
        .padding(.vertical, AppTheme.smallSpacing)
    }
}

// MARK: - Export View (Placeholder)
struct ExportView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Export functionality will be implemented here")
                    .foregroundColor(AppTheme.secondaryText)
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(CurrencyManager.shared)
} 