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
    @State private var isCurrencyExpanded = false
    @State private var isReceiptApplianceExpanded = false
    @State private var isNotificationsRemindersExpanded = false
    @State private var isSecurityPrivacyExpanded = false
    @State private var isBackupSyncExpanded = false
    @State private var isDataManagementExpanded = false
    
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                // Page Title at top left
                Text("Settings")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(AppTheme.text)
                    .padding(.horizontal, 24) // 24pt side insets
                
                profilePersonalizationSection
                    .padding(.top, 24) // Group top margin 24 from page header
                
                receiptApplianceSection
                    .padding(.top, 16) // Group→group 16pt
                
                notificationsRemindersSection
                    .padding(.top, 16) // Group→group 16pt
                
                // securityPrivacySection // Hidden as requested
                
                backupSyncSection
                    .padding(.top, 16) // Group→group 16pt
                
                dataManagementSection
                    .padding(.top, 16) // Group→group 16pt
                }
                .padding(.horizontal, 24) // 24pt side insets for full-bleed cards
            }
            .scrollContentBackground(.hidden) // Hide list background
            .padding(.bottom, AppTheme.tabBarBottomPadding)
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete All Data", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("This will permanently delete all receipts and associated files. This action cannot be undone.")
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
                Menu {
                    ForEach(currencyManager.getCurrencyList(), id: \.0) { currency in
                        Button(action: {
                            currencyManager.currentCurrency = currency.0
                        }) {
                            HStack {
                                Text(currency.1)
                                if currencyManager.currentCurrency == currency.0 {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(currencyManager.shortCode)
                            .foregroundColor(AppTheme.primary)
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .foregroundColor(AppTheme.primary)
                            .font(.caption2)
                    }
                }
                .accessibilityLabel(currencyManager.currencyName)
            }
        }
    }
    
    // MARK: - Receipt & Appliance Settings Section
    
    private var receiptApplianceSection: some View {
        ExpandableSettingsSection(
            title: "Receipt & Appliance", 
            icon: "doc.text.fill", 
            isExpanded: $isReceiptApplianceExpanded
        ) {
            SettingsRow(
                title: "Categories",
                subtitle: "Manage organisation",
                icon: "folder.fill"
            ) {
                Button("Manage") {
                    showingReceiptCategories = true
                }
                .foregroundColor(AppTheme.primary)
            }
            
            SettingsRow(
                title: "Warranty Reminder",
                subtitle: "Set default reminder periods",
                icon: "bell.badge.fill"
            ) {
                Button("Configure") {
                    showingReminderManagement = true
                }
                .foregroundColor(AppTheme.primary)
            }
            
            SettingsRow(
                title: "Storage Preferences",
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
                subtitle: "Personalise your reminder notifications",
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
                Menu {
                    Button(action: {
                        Task {
                            if let url = await DataBackupManager.shared.exportData() {
                                exportAlertMessage = "Exported to \(url.lastPathComponent)"
                                showingExportAlert = true
                            }
                        }
                    }) {
                        Label("Export ZIP", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: {
                        showingImportPicker = true
                    }) {
                        Label("Import ZIP", systemImage: "square.and.arrow.down")
                    }
                } label: {
                    Text("Manage")
                        .font(.headline)
                }
                .tint(AppTheme.primary)
                .accessibilityLabel("Manage import and export")
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
                    .rlHeadline()
                
                Spacer()
            }
            
            VStack(spacing: AppTheme.smallSpacing) {
                content
            }
        }
        .padding()
        .background(Color.clear) // Parent paints bg
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
                HStack(spacing: 12) { // Icon to text gap 12pt (match reminders)
                    Image(systemName: icon)
                        .foregroundColor(AppTheme.primary)
                        .font(.title3)
                        .frame(width: 36, height: 36) // Icon 36pt (match reminders)
                    
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
            }
            .buttonStyle(PlainButtonStyle())
            
            // Content with animation
            if isExpanded {
                VStack(spacing: 0) { // No spacing, rows handle their own spacing
                    content
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
        }
        .card() // Apply standard card styling
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
        VStack(alignment: .leading, spacing: 8) {
            // LINE 1: Title + trailing action
            HStack(spacing: 0) {
                // Reserve the same leading width as header icon + gap so title starts at section title x
                Spacer()
                    .frame(width: SettingsMetrics.textLeading - SettingsMetrics.cardH)
                
                // Title begins exactly at section-title x
                Text(title)
                    .font(.body)
                    .foregroundColor(AppTheme.text)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Spacer(minLength: 0)
                
                // Trailing action aligns with card's trailing (same as chevron)
                content
            }
            
            // LINE 2: Subtitle begins at the same textLeading
            HStack(spacing: 0) {
                Spacer()
                    .frame(width: SettingsMetrics.textLeading - SettingsMetrics.cardH)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer(minLength: 0)
            }
        }
        .padding(.vertical, 10)
        // Draw the ROW ICON inside the reserved block so the text start doesn’t shift
        .overlay(alignment: .leading) {
            HStack(spacing: SettingsMetrics.rowGap) {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: SettingsMetrics.rowIcon, height: SettingsMetrics.rowIcon)
                    .foregroundColor(AppTheme.secondaryText)
                // empty label to preserve the gap; real text starts after reserved width
                Color.clear.frame(width: 0, height: 0)
            }
            .frame(width: SettingsMetrics.textLeading - SettingsMetrics.cardH, alignment: .trailing)
        }
        .background(Color.clear) // Flat inside outer card
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