//
//  SettingsView.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI

struct SettingsView: View {
    @State private var showingExportSheet = false
    @State private var showingImportPicker = false
    @State private var showingDeleteAlert = false
    @State private var showingReminderManagement = false
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
    
    // Expandable sections state
    @State private var isCurrencyExpanded = true
    @State private var isReceiptApplianceExpanded = true
    @State private var isNotificationsRemindersExpanded = true
    @State private var isSecurityPrivacyExpanded = true
    @State private var isBackupSyncExpanded = true
    @State private var isDataManagementExpanded = true
    @State private var isAboutSupportExpanded = true
    
    var body: some View {
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
        ExpandableSettingsSection(
            title: "Currency Settings", 
            icon: "creditcard.fill", 
            isExpanded: $isCurrencyExpanded
        ) {
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
        }
    }
    
    // MARK: - Receipt & Appliance Settings Section
    
    private var receiptApplianceSection: some View {
        ExpandableSettingsSection(
            title: "Receipt & Appliance Settings", 
            icon: "doc.text.fill", 
            isExpanded: $isReceiptApplianceExpanded
        ) {
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
        ExpandableSettingsSection(
            title: "Notifications & Reminders", 
            icon: "bell.fill", 
            isExpanded: $isNotificationsRemindersExpanded
        ) {
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
        ExpandableSettingsSection(
            title: "Security & Privacy", 
            icon: "lock.shield.fill", 
            isExpanded: $isSecurityPrivacyExpanded
        ) {
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
        ExpandableSettingsSection(
            title: "Backup & Sync", 
            icon: "icloud.fill", 
            isExpanded: $isBackupSyncExpanded
        ) {
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
        ExpandableSettingsSection(
            title: "Data Management", 
            icon: "folder.fill", 
            isExpanded: $isDataManagementExpanded
        ) {
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
        ExpandableSettingsSection(
            title: "About & Support", 
            icon: "info.circle.fill", 
            isExpanded: $isAboutSupportExpanded
        ) {
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

// MARK: - Expandable Settings Section Component
struct ExpandableSettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @Binding var isExpanded: Bool
    let content: Content
    
    init(title: String, icon: String, isExpanded: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self._isExpanded = isExpanded
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with arrow
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(AppTheme.primary)
                        .font(.title2)
                    
                    Text(title)
                        .font(.headline)
                        .foregroundColor(AppTheme.text)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(AppTheme.secondaryText)
                        .font(.title3)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.3), value: isExpanded)
                }
                .padding()
            }
            .buttonStyle(PlainButtonStyle())
            
            // Content with animation
            if isExpanded {
                VStack(spacing: AppTheme.smallSpacing) {
                    content
                }
                .padding(.horizontal)
                .padding(.bottom)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
        }
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