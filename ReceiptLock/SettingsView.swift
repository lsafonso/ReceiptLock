//
//  SettingsView.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultReminderDays") private var defaultReminderDays = 7
    @AppStorage("selectedTheme") private var selectedTheme = "system"
    @State private var showingExportSheet = false
    @State private var showingImportPicker = false
    @State private var showingDeleteAlert = false
    
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
                title: "Default Reminder",
                subtitle: "\(defaultReminderDays) days before expiry",
                icon: "clock.fill"
            ) {
                Stepper("", value: $defaultReminderDays, in: 1...90)
                    .labelsHidden()
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
                title: "Privacy Policy",
                subtitle: "Read our privacy policy",
                icon: "hand.raised.fill"
            ) {
                Link("View", destination: URL(string: "https://example.com/privacy")!)
                    .foregroundColor(AppTheme.primary)
            }
            
            SettingsRow(
                title: "Terms of Service",
                subtitle: "Read our terms of service",
                icon: "doc.text.fill"
            ) {
                Link("View", destination: URL(string: "https://example.com/terms")!)
                    .foregroundColor(AppTheme.primary)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func deleteAllData() {
        // This would be implemented to delete all Core Data and files
        print("Delete all data functionality would be implemented here")
    }
    
    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            print("Import from: \(url)")
            // Implement import logic here
        case .failure(let error):
            print("Import error: \(error)")
        }
    }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(AppTheme.primary)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.text)
            }
            
            VStack(spacing: 1) {
                content()
            }
            .cardBackground()
        }
    }
}

// MARK: - Settings Row
struct SettingsRow<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    @ViewBuilder let trailing: () -> Content
    
    init(
        title: String,
        subtitle: String,
        icon: String,
        @ViewBuilder trailing: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.trailing = trailing
    }
    
    var body: some View {
        HStack(spacing: AppTheme.spacing) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppTheme.secondaryText)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.text)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            Spacer()
            
            trailing()
        }
        .padding(AppTheme.spacing)
    }
}

// MARK: - Export View
struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isExporting = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.largeSpacing) {
                Spacer()
                
                Image(systemName: "square.and.arrow.up.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(AppTheme.primary)
                
                VStack(spacing: AppTheme.smallSpacing) {
                    Text("Export Data")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.text)
                    
                    Text("Create a backup of all your receipts and associated files.")
                        .font(.body)
                        .foregroundColor(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppTheme.largeSpacing)
                }
                
                if isExporting {
                    ProgressView("Exporting...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Button("Export Now") {
                        exportData()
                    }
                    .primaryButton()
                }
                
                Spacer()
            }
            .padding(AppTheme.largeSpacing)
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func exportData() {
        isExporting = true
        
        // Simulate export process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isExporting = false
            dismiss()
        }
    }
}

#Preview {
    SettingsView()
} 