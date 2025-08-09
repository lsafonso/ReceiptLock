import SwiftUI
import LocalAuthentication

struct SecuritySettingsView: View {
    @StateObject private var biometricManager = BiometricAuthenticationManager.shared
    @StateObject private var privacyManager = PrivacyManager.shared
    @StateObject private var secureStorage = SecureStorageManager.shared
    
    @State private var showingBiometricSetup = false
    @State private var showingPrivacyPolicy = false
    @State private var showingDataExport = false
    @State private var showingDeleteConfirmation = false
    @State private var showingSecurityAudit = false
    @State private var securityAuditResult: SecurityAuditResult?
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - Biometric Authentication Section
                Section(header: Text("Biometric Authentication")) {
                    HStack {
                        Image(systemName: biometricManager.biometricType == .faceID ? "faceid" : "touchid")
                            .foregroundColor(.blue)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(biometricManager.biometricTypeDescription)
                                .font(.headline)
                            Text(biometricManager.isBiometricAvailable ? "Available" : "Not Available")
                                .font(.caption)
                                .foregroundColor(biometricManager.isBiometricAvailable ? .green : .red)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $privacyManager.privacySettings.biometricLockEnabled)
                            .onChange(of: privacyManager.privacySettings.biometricLockEnabled) { newValue in
                                if newValue && !biometricManager.isBiometricAvailable {
                                    showingBiometricSetup = true
                                    privacyManager.privacySettings.biometricLockEnabled = false
                                }
                            }
                    }
                    
                    if biometricManager.isBiometricAvailable {
                        Button("Test Authentication") {
                            Task {
                                let success = await biometricManager.authenticate()
                                if success {
                                    // Show success feedback
                                }
                            }
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                // MARK: - Privacy Controls Section
                Section(header: Text("Privacy Controls")) {
                    Toggle("Enable Notifications", isOn: $privacyManager.privacySettings.notificationsEnabled)
                    
                    Toggle("Data Sharing", isOn: $privacyManager.privacySettings.dataSharingEnabled)
                        .onChange(of: privacyManager.privacySettings.dataSharingEnabled) { newValue in
                            if newValue {
                                privacyManager.grantConsent(for: .dataSharing)
                            } else {
                                privacyManager.revokeConsent(for: .dataSharing)
                            }
                        }
                    
                    Toggle("Analytics", isOn: $privacyManager.privacySettings.analyticsEnabled)
                        .onChange(of: privacyManager.privacySettings.analyticsEnabled) { newValue in
                            if newValue {
                                privacyManager.grantConsent(for: .analytics)
                            } else {
                                privacyManager.revokeConsent(for: .analytics)
                            }
                        }
                    
                    Toggle("Crash Reporting", isOn: $privacyManager.privacySettings.crashReportingEnabled)
                        .onChange(of: privacyManager.privacySettings.crashReportingEnabled) { newValue in
                            if newValue {
                                privacyManager.grantConsent(for: .crashReporting)
                            } else {
                                privacyManager.revokeConsent(for: .crashReporting)
                            }
                        }
                }
                
                // MARK: - Data Retention Section
                Section(header: Text("Data Retention Policy")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Receipts: \(privacyManager.dataRetentionPolicy.receiptRetentionValue) years")
                        Text("Images: \(privacyManager.dataRetentionPolicy.imageRetentionValue) years")
                        Text("Logs: \(privacyManager.dataRetentionPolicy.logRetentionValue) months")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    Button("Configure Retention Policy") {
                        // Show retention policy configuration
                    }
                    .foregroundColor(.blue)
                }
                
                // MARK: - GDPR Compliance Section
                Section(header: Text("GDPR Compliance")) {
                    Button("Export My Data") {
                        showingDataExport = true
                    }
                    .foregroundColor(.blue)
                    
                    Button("View Privacy Policy") {
                        showingPrivacyPolicy = true
                    }
                    .foregroundColor(.blue)
                    
                    Button("Manage Consent") {
                        // Show consent management
                    }
                    .foregroundColor(.blue)
                    
                    Button("Anonymize My Data") {
                        // Show anonymization options
                    }
                    .foregroundColor(.orange)
                    
                    Button("Delete All Data") {
                        showingDeleteConfirmation = true
                    }
                    .foregroundColor(.red)
                }
                
                // MARK: - Security Audit Section
                Section(header: Text("Security Audit")) {
                    Button("Run Security Audit") {
                        securityAuditResult = secureStorage.performSecurityAudit()
                        showingSecurityAudit = true
                    }
                    .foregroundColor(.blue)
                    
                    if let result = securityAuditResult {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Security Level:")
                                Spacer()
                                Text(result.securityLevel.rawValue)
                                    .foregroundColor(Color(result.securityLevel.color))
                                    .fontWeight(.semibold)
                            }
                            
                            HStack {
                                Text("Overall Score:")
                                Spacer()
                                Text("\(result.overallSecurityScore)/100")
                                    .fontWeight(.semibold)
                            }
                        }
                        .font(.caption)
                    }
                }
                
                // MARK: - Advanced Security Section
                Section(header: Text("Advanced Security")) {
                    Button("Rotate Encryption Keys") {
                        // Show key rotation confirmation
                    }
                    .foregroundColor(.orange)
                    
                    Button("Clear Encryption Keys") {
                        // Show key clearing confirmation
                    }
                    .foregroundColor(.red)
                    
                    Button("View Security Logs") {
                        // Show security logs
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Security & Privacy")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingBiometricSetup) {
            BiometricSetupView()
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingDataExport) {
            DataExportView()
        }
        .sheet(isPresented: $showingSecurityAudit) {
            SecurityAuditView(auditResult: securityAuditResult ?? SecurityAuditResult())
        }
        .alert("Delete All Data", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("This action cannot be undone. All your receipts, images, and settings will be permanently deleted.")
        }
    }
    
    private func deleteAllData() {
        let success = privacyManager.deleteUserData()
        if success {
            // Show success message and reset app
            print("All data deleted successfully")
        } else {
            // Show error message
            print("Failed to delete data")
        }
    }
}

// MARK: - Biometric Setup View

struct BiometricSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var biometricManager = BiometricAuthenticationManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: biometricManager.biometricType == .faceID ? "faceid" : "touchid")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Set Up \(biometricManager.biometricTypeDescription)")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("To use \(biometricManager.biometricTypeDescription), you need to set it up in your device settings first.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Button("Open Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Setup Required")
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
}

// MARK: - Privacy Policy View

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Privacy Policy")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Last updated: \(Date().formatted(date: .long, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Group {
                        Text("Data Collection")
                            .font(.headline)
                        Text("We collect only the data necessary to provide our service. This includes receipt information, images, and basic app usage data.")
                        
                        Text("Data Usage")
                            .font(.headline)
                        Text("Your data is used solely to provide receipt management functionality. We do not sell, rent, or share your personal information with third parties.")
                        
                        Text("Data Security")
                            .font(.headline)
                        Text("All data is encrypted using AES-256 encryption and stored securely on your device. We use Face ID/Touch ID for additional security.")
                        
                        Text("Data Retention")
                            .font(.headline)
                        Text("Receipt data is retained for 7 years by default, but you can configure this in the app settings. You can export or delete your data at any time.")
                        
                        Text("Your Rights")
                            .font(.headline)
                        Text("Under GDPR, you have the right to access, export, correct, or delete your personal data. You can also withdraw consent at any time.")
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Privacy Policy")
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
}

// MARK: - Data Export View

struct DataExportView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var privacyManager = PrivacyManager.shared
    @State private var exportData: Data?
    @State private var isExporting = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Export Your Data")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Export all your data in a structured format for backup or transfer purposes.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                if let exportData = exportData {
                    Button("Share Export File") {
                        shareExportFile(exportData)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Generate Export") {
                        generateExport()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isExporting)
                }
                
                if isExporting {
                    ProgressView("Generating export...")
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Data Export")
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
    
    private func generateExport() {
        isExporting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let export = privacyManager.exportUserData()
            
            do {
                let data = try JSONEncoder().encode(export)
                
                DispatchQueue.main.async {
                    self.exportData = data
                    self.isExporting = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isExporting = false
                    // Show error
                }
            }
        }
    }
    
    private func shareExportFile(_ data: Data) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("receiptlock_export.json")
        
        do {
            try data.write(to: tempURL)
            
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(activityVC, animated: true)
            }
        } catch {
            print("Error sharing export file: \(error)")
        }
    }
}

// MARK: - Security Audit View

struct SecurityAuditView: View {
    @Environment(\.dismiss) private var dismiss
    let auditResult: SecurityAuditResult
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Security Score Card
                    VStack(spacing: 15) {
                        Text("Security Score")
                            .font(.headline)
                        
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 15)
                                .frame(width: 120, height: 120)
                            
                            Circle()
                                .trim(from: 0, to: CGFloat(auditResult.overallSecurityScore) / 100)
                                .stroke(Color(auditResult.securityLevel.color), lineWidth: 15)
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 1), value: auditResult.overallSecurityScore)
                            
                            VStack {
                                Text("\(auditResult.overallSecurityScore)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                Text("/100")
                                    .font(.caption)
                            }
                        }
                        
                        Text(auditResult.securityLevel.rawValue)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(auditResult.securityLevel.color))
                        
                        Text(auditResult.securityLevel.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    
                    // Detailed Results
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Security Details")
                            .font(.headline)
                        
                        SecurityDetailRow(
                            title: "Encryption Keys",
                            isEnabled: auditResult.encryptionKeysPresent,
                            description: "AES-256 encryption keys are properly configured"
                        )
                        
                        SecurityDetailRow(
                            title: "Biometric Authentication",
                            isEnabled: auditResult.biometricAvailable,
                            description: "Face ID/Touch ID is available and configured"
                        )
                        
                        SecurityDetailRow(
                            title: "Privacy Settings",
                            isEnabled: auditResult.privacySettingsConfigured,
                            description: "Privacy controls are properly configured"
                        )
                        
                        SecurityDetailRow(
                            title: "Data Retention",
                            isEnabled: auditResult.dataRetentionPolicyConfigured,
                            description: "Data retention policy is configured"
                        )
                    }
                    
                    // Consent Status
                    if !auditResult.consentStatus.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Consent Status")
                                .font(.headline)
                            
                            ForEach(auditResult.consentStatus, id: \.0) { consentType, hasConsent in
                                ConsentStatusRow(
                                    consentType: consentType,
                                    hasConsent: hasConsent
                                )
                            }
                        }
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Security Audit")
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
}

// MARK: - Helper Views

struct SecurityDetailRow: View {
    let title: String
    let isEnabled: Bool
    let description: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isEnabled ? .green : .red)
        }
        .padding(.vertical, 8)
    }
}

struct ConsentStatusRow: View {
    let consentType: ConsentType
    let hasConsent: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(consentType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(consentType.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: hasConsent ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(hasConsent ? .green : .red)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    SecuritySettingsView()
}
