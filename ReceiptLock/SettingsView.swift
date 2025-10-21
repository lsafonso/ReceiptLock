//
//  SettingsView.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("selectedTheme") private var selectedTheme = "system"
    @AppStorage("selectedLanguage") private var selectedLanguage = "en_US"
    @State private var showingExportSheet = false
    @State private var showingImportPicker = false
    @State private var showingDeleteAlert = false
    @State private var showingReminderManagement = false
    @State private var showingProfileEdit = false
    @State private var showingOnboardingReset = false
    @State private var showingReceiptCategories = false
    @State private var showingStoragePreferences = false
    @State private var showingNotificationPreferences = false
    @State private var showingCustomReminderMessages = false
    @State private var showingStorageUsage = false
    @State private var showingRestartAlert = false
    @State private var showingExportAlert = false
    @State private var exportAlertMessage = ""
    @State private var showingImportAlert = false
    @State private var importAlertMessage = ""
    @StateObject private var backupManager = DataBackupManager.shared
    @StateObject private var currencyManager = CurrencyManager.shared
    @StateObject private var profileManager = UserProfileManager.shared
    
    let themes = [
        ("system", "System"),
        ("light", "Light"),
        ("dark", "Dark")
    ]
    
    let languages = [
        ("en_US", "English (US)"),
        ("en_GB", "English (UK)"),
        ("es_ES", "Español"),
        ("fr_FR", "Français"),
        ("de_DE", "Deutsch"),
        ("it_IT", "Italiano"),
        ("pt_BR", "Português (Brasil)"),
        ("ja_JP", "日本語"),
        ("ko_KR", "한국어"),
        ("zh_CN", "中文 (简体)")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: AppTheme.largeSpacing) {
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
        .sheet(isPresented: $showingReceiptCategories) {
            ReceiptCategoriesView()
        }
        .sheet(isPresented: $showingStoragePreferences) {
            StoragePreferencesView()
        }
        .sheet(isPresented: $showingNotificationPreferences) {
            NotificationPreferencesView()
        }
        .sheet(isPresented: $showingCustomReminderMessages) {
            CustomReminderMessagesView()
        }
        .sheet(isPresented: $showingStorageUsage) {
            StorageUsageView()
        }
        .alert("Restart Required", isPresented: $showingRestartAlert) {
            Button("OK") { }
        } message: {
            Text("Please restart the app to apply iCloud Sync settings.")
        }
        .alert("Export Complete", isPresented: $showingExportAlert) {
            Button("OK") { }
        } message: {
            Text(exportAlertMessage)
        }
        .alert("Import Complete", isPresented: $showingImportAlert) {
            Button("OK") { }
        } message: {
            Text(importAlertMessage)
        }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [.zip],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result: result)
        }
    }
    

    
    // MARK: - Profile & Personalization Section
    
    private var profilePersonalizationSection: some View {
        SettingsSection(title: "Profile & Personalization", icon: "person.badge.plus.fill") {
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
            .padding(.bottom, AppTheme.spacing)
            
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
                subtitle: languages.first { $0.0 == selectedLanguage }?.1 ?? "English (US)",
                icon: "globe"
            ) {
                Picker("Language", selection: $selectedLanguage) {
                    ForEach(languages, id: \.0) { language in
                        Text(language.1).tag(language.0)
                    }
                }
                .pickerStyle(.menu)
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
                title: "Receipt Categories",
                subtitle: "Manage receipt organization",
                icon: "folder.fill"
            ) {
                Button("Manage") {
                    showingReceiptCategories = true
                }
                .foregroundColor(AppTheme.primary)
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
                Button("Configure") {
                    showingStoragePreferences = true
                }
                .foregroundColor(AppTheme.primary)
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
                Button("Configure") {
                    showingNotificationPreferences = true
                }
                .foregroundColor(AppTheme.primary)
            }
            
            SettingsRow(
                title: "Custom Reminder Messages",
                subtitle: "Personalize your reminder notifications",
                icon: "text.bubble.fill"
            ) {
                Button("Configure") {
                    showingCustomReminderMessages = true
                }
                .foregroundColor(AppTheme.primary)
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
                    set: {
                        DataBackupManager.shared.setCloudKitEnabled($0)
                        showingRestartAlert = true
                    }
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
            
            if let lastBackup = backupManager.lastBackupDate {
                SettingsRow(
                    title: "Last Backup",
                    subtitle: lastBackup.formatted(date: .abbreviated, time: .shortened),
                    icon: "clock.fill"
                ) {
                    EmptyView()
                }
            }
            
            SettingsRow(
                title: "Import/Export (ZIP)",
                subtitle: "Backup and restore data as ZIP",
                icon: "arrow.triangle.2.circlepath"
            ) {
                HStack(spacing: AppTheme.smallSpacing) {
                    Button("Export ZIP") {
                        Task {
                            if let url = await DataBackupManager.shared.exportData() {
                                exportAlertMessage = "Exported to \(url.lastPathComponent)"
                                showingExportAlert = true
                            }
                        }
                    }
                    .foregroundColor(AppTheme.primary)
                    
                    Button("Import ZIP") {
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
                Button("View") {
                    showingStorageUsage = true
                }
                .foregroundColor(AppTheme.primary)
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
                subtitle: appVersion,
                icon: "app.badge.fill"
            ) {
                EmptyView()
            }
            
            SettingsRow(
                title: "Build",
                subtitle: appBuild,
                icon: "hammer.fill"
            ) {
                EmptyView()
            }
            
            SettingsRow(
                title: "Terms & Privacy",
                subtitle: "Read our terms and privacy policy",
                icon: "doc.text.fill"
            ) {
                NavigationLink("View") {
                    TermsPrivacyView()
                }
                .foregroundColor(AppTheme.primary)
            }
            
            SettingsRow(
                title: "Support & Feedback",
                subtitle: "Get help and send feedback",
                icon: "questionmark.circle.fill"
            ) {
                NavigationLink("Contact") {
                    SupportFeedbackView()
                }
                .foregroundColor(AppTheme.primary)
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
        let success = PrivacyManager.shared.deleteUserData()
        if success {
            // Optionally show a confirmation or reset in-app state
            UserProfileManager.shared.resetOnboarding()
        }
    }
    
    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            Task {
                let success = await DataBackupManager.shared.importData(from: url)
                await MainActor.run {
                    if success {
                        importAlertMessage = "Imported from \(url.lastPathComponent)"
                        showingImportAlert = true
                    }
                }
            }
        case .failure(let error):
            print("Import failed: \(error)")
        }
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

// MARK: - Terms & Privacy View
struct TermsPrivacyView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.spacing) {
                    Text("Terms of Service")
                        .font(.title2.weight(.semibold))
                    Text("By using ReceiptLock, you agree to the following terms...")
                        .foregroundColor(AppTheme.secondaryText)
                    Divider()
                    Text("Privacy Policy")
                        .font(.title2.weight(.semibold))
                    Text("We value your privacy. All data is stored on-device and protected with encryption and biometrics.")
                        .foregroundColor(AppTheme.secondaryText)
                }
                .padding(AppTheme.spacing)
            }
            .navigationTitle("Terms & Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Support & Feedback View
struct SupportFeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var message: String = ""
    @State private var email: String = ""
    var body: some View {
        NavigationStack {
            Form {
                Section("Contact") {
                    TextField("Email (optional)", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                Section("Message") {
                    TextEditor(text: $message)
                        .frame(minHeight: 120)
                }
                Section {
                    Button("Send Feedback") {
                        sendFeedback()
                    }
                    .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Support & Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    private func sendFeedback() {
        // Basic mailto fallback
        let subject = "ReceiptLock Feedback"
        let body = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let address = email.isEmpty ? "support@example.com" : email
        if let url = URL(string: "mailto:\(address)?subject=\(subject)&body=\(body)") {
            UIApplication.shared.open(url)
        }
        dismiss()
    }
}

#Preview {
    SettingsView()
        .environmentObject(CurrencyManager.shared)
} 

// MARK: - App Info Helpers
private var appVersion: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
}

private var appBuild: String {
    Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
} 