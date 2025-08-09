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
    
    let themes = [
        ("system", "System"),
        ("light", "Light"),
        ("dark", "Dark")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: AppTheme.largeSpacing) {
                    notificationsSection
                    appearanceSection
                    backupSyncSection
                    dataManagementSection
                    aboutSection
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
        .sheet(isPresented: $showingExportSheet) {
            ExportView()
        }
        .sheet(isPresented: $showingReminderManagement) {
            ReminderManagementView()
        }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [.zip],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result: result)
        }
    }
    
    // MARK: - Section Views
    
    private var notificationsSection: some View {
        SettingsSection(title: "Notifications", icon: "bell.fill") {
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
            
            // Show current reminder status
            let enabledCount = ReminderManager.shared.preferences.enabledReminders.count
            SettingsRow(
                title: "Active Reminders",
                subtitle: "\(enabledCount) reminders configured",
                icon: "checkmark.circle.fill"
            ) {
                EmptyView()
            }
        }
    }
    
    private var appearanceSection: some View {
        SettingsSection(title: "Appearance", icon: "paintbrush.fill") {
            SettingsRow(
                title: "Theme",
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
        }
    }
    
    private var dataManagementSection: some View {
        SettingsSection(title: "Data Management", icon: "folder.fill") {
            SettingsRow(
                title: "Export Data",
                subtitle: "Backup all receipts and files",
                icon: "square.and.arrow.up.fill"
            ) {
                Button("Export") {
                    showingExportSheet = true
                }
                .foregroundColor(AppTheme.primary)
            }
            
            SettingsRow(
                title: "Import Data",
                subtitle: "Restore from backup",
                icon: "square.and.arrow.down.fill"
            ) {
                Button("Import") {
                    showingImportPicker = true
                }
                .foregroundColor(AppTheme.primary)
            }
            
            SettingsRow(
                title: "Delete All Data",
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
    
    private var aboutSection: some View {
        SettingsSection(title: "About", icon: "info.circle.fill") {
            SettingsRow(
                title: "Version",
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
} 