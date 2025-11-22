//
//  ImportBackupView.swift
//  ReceiptLock
//
//  Created by Assistant on 22/11/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct ImportBackupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingFileImporter = false
    @State private var importStatus: ImportStatus = .idle
    @State private var alertMessage = ""
    @State private var showAlert = false
    
    enum ImportStatus {
        case idle
        case importing
        case success
        case error
    }
    
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                SheetHeaderView(
                    title: "Import Backup",
                    isSaving: false,
                    saveDisabled: true,
                    saveButtonTitle: "", // Hides the button text
                    onCancel: { dismiss() },
                    onSave: { },
                    scrollOffset: 0
                )
                .padding(.top, AppTheme.smallSpacing)
                .background(AppTheme.background)
                .zIndex(1)
                
                // Content
                VStack(spacing: AppTheme.largeSpacing) {
                    Spacer()
                    
                    VStack(spacing: AppTheme.largeSpacing) {
                        Image(systemName: "arrow.down.doc.fill")
                            .font(.system(size: 64))
                            .foregroundColor(AppTheme.primary)
                            .padding()
                            .background(
                                Circle()
                                    .fill(AppTheme.primary.opacity(0.1))
                                    .frame(width: 120, height: 120)
                            )
                        
                        VStack(spacing: AppTheme.spacing) {
                            Text("Restore from Backup")
                                .font(.title2.bold())
                                .foregroundColor(AppTheme.text)
                            
                            Text("Select your ZIP backup file to restore your data.")
                                .font(.body)
                                .foregroundColor(AppTheme.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            
                            Text("Note: This will replace your current data.")
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)
                                .padding(.top, 4)
                        }
                    }
                    
                    if importStatus == .importing {
                        VStack(spacing: AppTheme.spacing) {
                            ProgressView()
                                .tint(AppTheme.primary)
                                .scaleEffect(1.2)
                            
                            Text("Importing Data...")
                                .font(.headline)
                                .foregroundColor(AppTheme.primary)
                        }
                        .padding(.top, AppTheme.largeSpacing)
                    } else {
                        Button {
                            isShowingFileImporter = true
                        } label: {
                            HStack {
                                Image(systemName: "folder.fill")
                                Text("Select ZIP from Files")
                            }
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.primary)
                            .cornerRadius(AppTheme.cornerRadius)
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, AppTheme.spacing)
                    }
                    
                    Spacer()
                    Spacer()
                }
                .padding(.bottom, AppTheme.tabBarBottomPadding)
            }
        }
        .fileImporter(
            isPresented: $isShowingFileImporter,
            allowedContentTypes: [.zip],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result: result)
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(importStatus == .success ? "Import Complete" : "Import Failed"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if importStatus == .success {
                        dismiss()
                    } else {
                        // Reset status on error so user can try again
                        importStatus = .idle
                    }
                }
            )
        }
    }
    
    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            importStatus = .importing
            
            Task {
                // Start accessing the security-scoped resource
                guard url.startAccessingSecurityScopedResource() else {
                    await MainActor.run {
                        importStatus = .error
                        alertMessage = "Permission denied to access file."
                        showAlert = true
                    }
                    return
                }
                
                // Ensure we stop accessing it when done
                defer { url.stopAccessingSecurityScopedResource() }
                
                let success = await DataBackupManager.shared.importData(from: url)
                
                await MainActor.run {
                    if success {
                        importStatus = .success
                        alertMessage = "Successfully imported data from \(url.lastPathComponent)"
                    } else {
                        importStatus = .error
                        alertMessage = "Failed to import data. The file might be corrupted or invalid."
                    }
                    showAlert = true
                }
            }
            
        case .failure(let error):
            importStatus = .error
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}

#Preview {
    ImportBackupView()
}

