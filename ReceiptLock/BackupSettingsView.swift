//
//  BackupSettingsView.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct BackupSettingsView: View {
    @StateObject private var backupManager = DataBackupManager.shared
    @State private var showingExportSheet = false
    @State private var showingImportPicker = false
    @State private var showingDeleteAlert = false
    @State private var selectedBackupURL: URL?
    @State private var exportedBackupURL: URL?
    @State private var showingSuccessAlert = false
    @State private var successMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.largeSpacing) {
                    // iCloud Sync Section
                    iCloudSyncSection
                    
                    // Manual Backup Section
                    manualBackupSection
                    
                    // Backup History Section
                    backupHistorySection
                    
                    // Data Management Section
                    dataManagementSection
                }
                .padding(AppTheme.spacing)
            }
            .navigationTitle("Backup & Sync")
            .navigationBarTitleDisplayMode(.large)
            .alert("Success", isPresented: $showingSuccessAlert) {
                Button("OK") { }
            } message: {
                Text(successMessage)
            }
            .alert("Delete Backup", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let url = selectedBackupURL {
                        deleteBackup(at: url)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this backup? This action cannot be undone.")
            }
            .sheet(isPresented: $showingExportSheet) {
                if let url = exportedBackupURL {
                    ShareSheet(items: [url])
                } else {
                    Text("No export available")
                }
            }
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [UTType.zip],
                allowsMultipleSelection: false
            ) { result in
                handleImportResult(result)
            }
        }
    }
    
    // MARK: - iCloud Sync Section
    private var iCloudSyncSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            HStack {
                Image(systemName: "icloud")
                    .foregroundColor(AppTheme.primary)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("iCloud Sync")
                        .font(.headline)
                    Text("Automatically sync your data across devices")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { backupManager.isCloudKitEnabled() },
                    set: { backupManager.setCloudKitEnabled($0) }
                ))
                .labelsHidden()
            }
            
            if backupManager.isCloudKitEnabled() {
                VStack(spacing: AppTheme.smallSpacing) {
                    HStack {
                        Text("Last Sync:")
                        Spacer()
                        if let lastSync = backupManager.lastBackupDate {
                            Text(lastSync, style: .relative)
                                .foregroundColor(AppTheme.secondaryText)
                        } else {
                            Text("Never")
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                    
                    Button("Sync Now") {
                        Task {
                            await backupManager.syncWithCloud()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(backupManager.isBackingUp)
                    
                    if backupManager.isBackingUp {
                        ProgressView(value: backupManager.syncProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                    }
                }
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.cornerRadius)
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadius)
    }
    
    // MARK: - Manual Backup Section
    private var manualBackupSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            Text("Manual Backup")
                .font(.headline)
            
            VStack(spacing: AppTheme.smallSpacing) {
                HStack {
                    Button("Export Data") {
                        Task {
                            await exportData()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(backupManager.isBackingUp)
                    
                    Spacer()
                    
                    Button("Import Data") {
                        showingImportPicker = true
                    }
                    .buttonStyle(.bordered)
                    .disabled(backupManager.isRestoring)
                }
                
                if backupManager.isBackingUp || backupManager.isRestoring {
                    HStack {
                        Text(backupManager.isBackingUp ? "Exporting..." : "Importing...")
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    .padding(.top, 4)
                }
                
                if case .failed(let error) = backupManager.backupStatus {
                    Text("Error: \(error)")
                        .foregroundColor(AppTheme.error)
                        .font(.caption)
                        .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadius)
    }
    
    // MARK: - Backup History Section
    private var backupHistorySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            Text("Backup History")
                .font(.headline)
            
            let backups = backupManager.listBackups()
            
            if backups.isEmpty {
                Text("No backups found")
                    .foregroundColor(AppTheme.secondaryText)
                    .italic()
                    .padding()
            } else {
                ForEach(backups, id: \.self) { backupURL in
                    BackupHistoryRow(
                        backupURL: backupURL,
                        onDelete: {
                            selectedBackupURL = backupURL
                            showingDeleteAlert = true
                        }
                    )
                }
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadius)
    }
    
    // MARK: - Data Management Section
    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            Text("Data Management")
                .font(.headline)
            
            VStack(spacing: AppTheme.smallSpacing) {
                Button("Clear All Data") {
                    showingDeleteAlert = true
                }
                .buttonStyle(.bordered)
                .foregroundColor(AppTheme.error)
                
                Text("This will permanently delete all receipts, appliances, and settings")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadius)
    }
    
    // MARK: - Helper Methods
    private func exportData() async {
        if let backupURL = await backupManager.exportData() {
            exportedBackupURL = backupURL
            successMessage = "Data exported successfully to \(backupURL.lastPathComponent)"
            showingSuccessAlert = true
            showingExportSheet = true
        }
    }
    
    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            Task {
                let success = await backupManager.importData(from: url)
                await MainActor.run {
                    if success {
                        successMessage = "Data imported successfully"
                        showingSuccessAlert = true
                    }
                }
            }
            
        case .failure(let error):
            print("Import failed: \(error)")
        }
    }
    
    private func deleteBackup(at url: URL) {
        if backupManager.deleteBackup(at: url) {
            successMessage = "Backup deleted successfully"
            showingSuccessAlert = true
        }
    }
}

// MARK: - Backup History Row
struct BackupHistoryRow: View {
    let backupURL: URL
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(backupURL.lastPathComponent)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let attributes = try? FileManager.default.attributesOfItem(atPath: backupURL.path),
                   let creationDate = attributes[.creationDate] as? Date {
                    Text("Created: \(creationDate, style: .date)")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(AppTheme.secondaryBackground)
        .cornerRadius(AppTheme.cornerRadius)
    }
}



// MARK: - Preview
#Preview {
    BackupSettingsView()
        .environmentObject(DataBackupManager.shared)
}
