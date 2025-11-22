//
//  SettingsView.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI

struct SettingsView: View {
    // MARK: - State Properties
    
    // Alert States
    @State private var showingDeleteAlert = false
    @State private var showingRestartAlert = false
    @State private var showingExportAlert = false
    @State private var exportAlertMessage = ""
    @State private var showingImportAlert = false
    @State private var importAlertMessage = ""
    
    // Sheet States
    @State private var showingReminderManagement = false
    @State private var showingImportPicker = false
    @State private var showingImportBackupView = false
    
    // Data Managers
    @StateObject private var backupManager = DataBackupManager.shared
    @StateObject private var currencyManager = CurrencyManager.shared
    @StateObject private var profileManager = UserProfileManager.shared
    
    // Expandable Sections State
    @State private var isCurrencyExpanded = false
    @State private var isNotificationsExpanded = false
    @State private var isBackupExpanded = false
    @State private var isAboutExpanded = false
    @State private var isDangerZoneExpanded = false
    
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    // Page Title
                    HStack {
                        Text("Settings")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(AppTheme.text)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, AppTheme.largeSpacing)
                    
                    // A. Currency
                    currencySection
                        .padding(.top, 16)
                    
                    // B. Notifications & Reminders
                    notificationsRemindersSection
                        .padding(.top, 16)
                    
                    // C. Backup & Sync
                    backupSyncSection
                        .padding(.top, 16)
                    
                    // D. Danger Zone (Reordered to be before About & Support)
                    dangerZoneSection
                        .padding(.top, 16)
                    
                    // E. About & Support (Reordered to be last)
                    aboutSupportSection
                        .padding(.top, 16)
                }
                .padding(.horizontal, 24)
            }
            .scrollContentBackground(.hidden)
            .padding(.bottom, AppTheme.tabBarBottomPadding)
        }
        .navigationBarTitleDisplayMode(.inline)
        // Alerts
        .alert("Delete All Data", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("This will permanently delete all receipts and associated files. This action cannot be undone.")
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
        // Sheets & Importers
        .sheet(isPresented: $showingReminderManagement) {
            ReminderManagementView()
        }
        .sheet(isPresented: $showingImportBackupView) {
            ImportBackupView()
        }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [.zip],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result: result)
        }
    }
    
    // MARK: - A. Currency Section
    
    private var currencySection: some View {
        ExpandableSettingsSection(
            title: "Currency",
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
    
    // MARK: - B. Notifications & Reminders Section
    
    private var notificationsRemindersSection: some View {
        ExpandableSettingsSection(
            title: "Notifications & Reminders",
            icon: "bell.fill",
            isExpanded: $isNotificationsExpanded
        ) {
            SettingsRow(
                title: "Reminder Settings",
                subtitle: "Configure multiple reminders",
                icon: "bell.badge.fill"
            ) {
                Button("Configure") {
                    showingReminderManagement = true
                }
                .foregroundColor(AppTheme.primary)
            }
        }
    }
    
    // MARK: - C. Backup & Sync Section
    
    private var backupSyncSection: some View {
        ExpandableSettingsSection(
            title: "Backup & Sync",
            icon: "icloud.fill",
            isExpanded: $isBackupExpanded
        ) {
            // iCloud Sync Toggle
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
            
            // Manual Backup & Restore (ZIP)
            SettingsRow(
                title: "Manual Backup & Restore",
                subtitle: "Export and import data as ZIP",
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
                        showingImportBackupView = true
                    }) {
                        Label("Import ZIP", systemImage: "square.and.arrow.down")
                    }
                } label: {
                    Text("Manage")
                        .font(.headline)
                }
                .tint(AppTheme.primary)
            }
        }
    }
    
    // MARK: - D. About & Support Section
    
    private var aboutSupportSection: some View {
        ExpandableSettingsSection(
            title: "About & Support",
            icon: "info.circle.fill",
            isExpanded: $isAboutExpanded
        ) {
            // App Version
            SettingsRow(
                title: "App Version",
                subtitle: getAppVersion(),
                icon: "app.badge.fill"
            ) {
                EmptyView()
            }
            
            // Privacy Policy
            SettingsRow(
                title: "Privacy Policy",
                subtitle: "View our privacy policy",
                icon: "hand.raised.fill"
            ) {
                Link(destination: URL(string: "https://tela51.dev/receiptlock/privacy")!) {
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(AppTheme.primary)
                }
            }
            
            // Terms of Use
            SettingsRow(
                title: "Terms of Use",
                subtitle: "View our terms of service",
                icon: "doc.text.fill"
            ) {
                Link(destination: URL(string: "https://tela51.dev/receiptlock/terms")!) {
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(AppTheme.primary)
                }
            }
            
            // Support
            SettingsRow(
                title: "Support",
                subtitle: "Get help and contact us",
                icon: "questionmark.circle.fill"
            ) {
                Link(destination: URL(string: "https://tela51.dev/receiptlock/support")!) {
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(AppTheme.primary)
                }
            }
            
            // Reset Onboarding (Optional/Debug)
             SettingsRow(
                 title: "Reset Onboarding",
                 subtitle: "For testing purposes",
                 icon: "arrow.counterclockwise"
             ) {
                 Button("Reset") {
                     UserProfileManager.shared.resetOnboarding()
                 }
                 .foregroundColor(AppTheme.primary)
             }
        }
    }
    
    // MARK: - E. Danger Zone Section
    
    private var dangerZoneSection: some View {
        ExpandableSettingsSection(
            title: "Danger Zone",
            icon: "exclamationmark.triangle.fill",
            isExpanded: $isDangerZoneExpanded
        ) {
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
    
    // MARK: - Helper Methods
    
    private func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    private func deleteAllData() {
        let success = PrivacyManager.shared.deleteUserData()
        if success {
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

// MARK: - Helper Components

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
        .background(Color.clear)
        .cornerRadius(AppTheme.cornerRadius)
    }
}

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
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .foregroundColor(AppTheme.primary)
                        .font(.title3)
                        .frame(width: 36, height: 36)
                    
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
                VStack(spacing: 0) {
                    content
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
        }
        .card()
    }
}

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
            HStack(spacing: 0) {
                Spacer()
                    .frame(width: SettingsMetrics.textLeading - SettingsMetrics.cardH)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(AppTheme.text)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Spacer(minLength: 0)
                
                content
            }
            
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
        .overlay(alignment: .leading) {
            HStack(spacing: SettingsMetrics.rowGap) {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: SettingsMetrics.rowIcon, height: SettingsMetrics.rowIcon)
                    .foregroundColor(AppTheme.secondaryText)
                Color.clear.frame(width: 0, height: 0)
            }
            .frame(width: SettingsMetrics.textLeading - SettingsMetrics.cardH, alignment: .trailing)
        }
        .background(Color.clear)
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
        .environmentObject(CurrencyManager.shared)
}
