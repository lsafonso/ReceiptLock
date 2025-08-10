import SwiftUI
import LocalAuthentication

struct SecuritySettingsView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var privacyManager = PrivacyManager.shared
    @StateObject private var secureStorage = SecureStorageManager.shared
    @StateObject private var biometricManager = BiometricAuthenticationManager.shared
    
    @State private var showingBiometricSetup = false
    @State private var showingPasscodeSetup = false
    @State private var showingSecurityAudit = false
    @State private var showingPrivacyPolicy = false
    @State private var showingDataExport = false
    @State private var showingDataDeletion = false
    @State private var showingConsentManagement = false
    
    @State private var securityAuditResult: SecurityAuditResult?
    @State private var isExportingData = false
    @State private var exportProgress: Double = 0.0
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - Authentication Section
                Section("Authentication") {
                    HStack {
                        Image(systemName: "lock.shield")
                            .foregroundColor(.blue)
                        Text("Biometric Authentication")
                        Spacer()
                        Toggle("", isOn: $privacyManager.privacySettings.biometricLockEnabled)
                            .onChange(of: privacyManager.privacySettings.biometricLockEnabled) { _, newValue in
                                if newValue {
                                    checkBiometricAvailability()
                                }
                            }
                    }
                    
                    if privacyManager.privacySettings.biometricLockEnabled {
                        HStack {
                            Image(systemName: biometricManager.biometricType == .faceID ? "faceid" : "touchid")
                                .foregroundColor(.green)
                            Text("Biometric Type")
                            Spacer()
                            Text(biometricManager.biometricTypeDescription)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "timer")
                                .foregroundColor(Color(red: 230/255, green: 154/255, blue: 100/255))
                            Text("Auto-Lock Timeout")
                            Spacer()
                            Text(formatTimeInterval(privacyManager.privacySettings.autoLockTimeout))
                                .foregroundColor(.secondary)
                        }
                        
                        Button("Configure Auto-Lock") {
                            showingPasscodeSetup = true
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                // MARK: - Security Section
                Section("Security") {
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(.purple)
                        Text("Encryption Status")
                        Spacer()
                        if let audit = securityAuditResult {
                            Text(audit.encryptionKeysPresent ? "Enabled" : "Disabled")
                                .foregroundColor(audit.encryptionKeysPresent ? AppTheme.success : AppTheme.error)
                        } else {
                            Text("Checking...")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "shield.checkered")
                            .foregroundColor(AppTheme.success)
                        Text("Security Level")
                        Spacer()
                        if let audit = securityAuditResult {
                            Text(audit.securityLevel.rawValue)
                                .foregroundColor(Color(audit.securityLevel.color))
                        } else {
                            Text("Calculating...")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button("Run Security Audit") {
                        runSecurityAudit()
                    }
                    .foregroundColor(.blue)
                }
                
                // MARK: - Privacy Section
                Section("Privacy") {
                    HStack {
                        Image(systemName: "hand.raised")
                            .foregroundColor(Color(red: 230/255, green: 154/255, blue: 100/255))
                        Text("Data Processing Consent")
                        Spacer()
                        Text(privacyManager.hasValidConsent(for: .dataProcessing) ? "Granted" : "Required")
                            .foregroundColor(privacyManager.hasValidConsent(for: .dataProcessing) ? AppTheme.success : AppTheme.error)
                    }
                    
                    HStack {
                        Image(systemName: "chart.bar")
                            .foregroundColor(.blue)
                        Text("Analytics")
                        Spacer()
                        Toggle("", isOn: $privacyManager.privacySettings.analyticsEnabled)
                            .onChange(of: privacyManager.privacySettings.analyticsEnabled) { _, newValue in
                                if newValue {
                                    privacyManager.grantConsent(for: .analytics)
                                } else {
                                    privacyManager.revokeConsent(for: .analytics)
                                }
                            }
                    }
                    
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                        Text("Crash Reporting")
                        Spacer()
                        Toggle("", isOn: $privacyManager.privacySettings.crashReportingEnabled)
                            .onChange(of: privacyManager.privacySettings.crashReportingEnabled) { _, newValue in
                                if newValue {
                                    privacyManager.grantConsent(for: .crashReporting)
                                } else {
                                    privacyManager.revokeConsent(for: .crashReporting)
                                }
                            }
                    }
                    
                    Button("Manage Consent") {
                        showingConsentManagement = true
                    }
                    .foregroundColor(.blue)
                }
                
                // MARK: - Data Management Section
                Section("Data Management") {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(AppTheme.success)
                        Text("Data Retention")
                        Spacer()
                        Text("\(privacyManager.dataRetentionPolicy.receiptRetentionValue) years")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Export My Data") {
                        showingDataExport = true
                    }
                    .foregroundColor(.blue)
                    
                    Button("Delete All Data") {
                        showingDataDeletion = true
                    }
                    .foregroundColor(.red)
                }
                
                // MARK: - Session Section
                Section("Current Session") {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.blue)
                        Text("Session Status")
                        Spacer()
                        Text(authManager.isAuthenticated ? "Active" : "Inactive")
                            .foregroundColor(authManager.isAuthenticated ? .green : .red)
                    }
                    
                    if let lastAuth = authManager.lastAuthenticationTime {
                        HStack {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.green)
                            Text("Last Authentication")
                            Spacer()
                            Text(lastAuth, style: .relative)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if authManager.isAuthenticated {
                        Button("Logout") {
                            authManager.logout()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Security & Privacy")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Dismiss the view
                    }
                }
            }
        }
        .onAppear {
            runSecurityAudit()
        }
        .sheet(isPresented: $showingBiometricSetup) {
            BiometricSetupView()
        }
        .sheet(isPresented: $showingPasscodeSetup) {
            AutoLockSetupView()
        }
        .sheet(isPresented: $showingSecurityAudit) {
            SecurityAuditView(auditResult: securityAuditResult ?? SecurityAuditResult())
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingDataExport) {
            DataExportView(isExporting: $isExportingData, progress: $exportProgress)
        }
        .sheet(isPresented: $showingDataDeletion) {
            DataDeletionConfirmationView()
        }
        .sheet(isPresented: $showingConsentManagement) {
            ConsentManagementView()
        }
    }
    
    // MARK: - Private Methods
    
    private func checkBiometricAvailability() {
        let status = biometricManager.checkBiometricSettings()
        
        if status != .available {
            showingBiometricSetup = true
        }
    }
    
    private func runSecurityAudit() {
        securityAuditResult = secureStorage.performSecurityAudit()
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - Supporting Views

struct BiometricSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var biometricManager = BiometricAuthenticationManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "faceid")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Biometric Setup Required")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("To use biometric authentication, you need to set up Face ID or Touch ID in your device settings.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 15) {
                    Button("Open Settings") {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Biometric Setup")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AutoLockSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var privacyManager = PrivacyManager.shared
    @State private var selectedTimeout: TimeInterval = 300
    
    private let timeoutOptions: [(String, TimeInterval)] = [
        ("30 seconds", 30),
        ("1 minute", 60),
        ("2 minutes", 120),
        ("5 minutes", 300),
        ("10 minutes", 600),
        ("15 minutes", 900),
        ("30 minutes", 1800),
        ("1 hour", 3600)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "timer")
                    .font(.system(size: 80))
                    .foregroundColor(Color(red: 230/255, green: 154/255, blue: 100/255))
                
                Text("Auto-Lock Configuration")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Choose how long the app should wait before automatically locking after inactivity.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Picker("Auto-Lock Timeout", selection: $selectedTimeout) {
                    ForEach(timeoutOptions, id: \.1) { option in
                        Text(option.0).tag(option.1)
                    }
                }
                .pickerStyle(.wheel)
                
                VStack(spacing: 15) {
                    Button("Save") {
                        privacyManager.privacySettings.autoLockTimeout = selectedTimeout
                        privacyManager.updatePrivacySettings(privacyManager.privacySettings)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Auto-Lock Setup")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            selectedTimeout = privacyManager.privacySettings.autoLockTimeout
        }
    }
}

struct SecurityAuditView: View {
    let auditResult: SecurityAuditResult
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 80))
                    .foregroundColor(Color(auditResult.securityLevel.color))
                
                Text("Security Audit Results")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                VStack(spacing: 20) {
                    SecurityScoreView(score: auditResult.overallSecurityScore, level: auditResult.securityLevel)
                    
                    VStack(spacing: 15) {
                        SecurityCheckRow(title: "Encryption Keys", isEnabled: auditResult.encryptionKeysPresent)
                        SecurityCheckRow(title: "Biometric Authentication", isEnabled: auditResult.biometricAvailable)
                        SecurityCheckRow(title: "Privacy Settings", isEnabled: auditResult.privacySettingsConfigured)
                        SecurityCheckRow(title: "Data Retention Policy", isEnabled: auditResult.dataRetentionPolicyConfigured)
                    }
                    
                    if !auditResult.consentStatus.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Consent Status:")
                                .font(.headline)
                            
                            ForEach(auditResult.consentStatus, id: \.0) { consentType, hasConsent in
                                HStack {
                                    Text(consentType.displayName)
                                    Spacer()
                                    Image(systemName: hasConsent ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(hasConsent ? AppTheme.success : AppTheme.error)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Security Audit")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SecurityScoreView: View {
    let score: Int
    let level: SecurityLevel
    
    var body: some View {
        VStack(spacing: 15) {
            ZStack {
                Circle()
                    .stroke(Color(.systemGray4), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100.0)
                    .stroke(Color(level.color), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: score)
                
                VStack {
                    Text("\(score)")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("/ 100")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(level.rawValue)
                .font(.headline)
                .foregroundColor(Color(level.color))
            
            Text(level.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct SecurityCheckRow: View {
    let title: String
    let isEnabled: Bool
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isEnabled ? AppTheme.success : AppTheme.error)
        }
        .padding(.horizontal)
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Privacy Policy")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("This app is committed to protecting your privacy and securing your data. We use industry-standard encryption and security measures to ensure your receipt information remains private and secure.")
                        .font(.body)
                    
                    Text("Data Collection")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("We only collect the data necessary to provide the app's functionality. This includes receipt images, purchase details, and warranty information that you choose to store.")
                        .font(.body)
                    
                    Text("Data Security")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("All data is encrypted using AES-256 encryption and stored securely on your device. Biometric authentication provides an additional layer of security.")
                        .font(.body)
                    
                    Text("Data Sharing")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("We do not share your personal data with third parties. All data processing occurs locally on your device.")
                        .font(.body)
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

struct DataExportView: View {
    @Binding var isExporting: Bool
    @Binding var progress: Double
    @Environment(\.dismiss) private var dismiss
    @StateObject private var privacyManager = PrivacyManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                if isExporting {
                    VStack(spacing: 20) {
                        ProgressView(value: progress)
                            .progressViewStyle(LinearProgressViewStyle())
                            .frame(width: 200)
                        
                        Text("Exporting your data...")
                            .font(.headline)
                        
                        Text("\(Int(progress * 100))%")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("Export Your Data")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Export all your data in a secure, encrypted format. This includes receipts, settings, and privacy preferences.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        Button("Start Export") {
                            startExport()
                        }
                        .buttonStyle(.borderedProminent)
                    }
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
    
    private func startExport() {
        isExporting = true
        progress = 0.0
        
        // Simulate export process
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            progress += 0.01
            if progress >= 1.0 {
                timer.invalidate()
                isExporting = false
                progress = 0.0
            }
        }
    }
}

struct DataDeletionConfirmationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var privacyManager = PrivacyManager.shared
    @State private var showingConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "trash")
                    .font(.system(size: 80))
                    .foregroundColor(AppTheme.error)
                
                Text("Delete All Data")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("This action will permanently delete all your data including receipts, images, and settings. This action cannot be undone.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 15) {
                    Button("Delete All Data") {
                        showingConfirmation = true
                    }
                    .buttonStyle(.borderedProminent)
                    .foregroundColor(AppTheme.error)
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Data Deletion")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Confirm Deletion", isPresented: $showingConfirmation) {
                Button("Delete", role: .destructive) {
                    deleteAllData()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete all your data? This action cannot be undone.")
            }
        }
    }
    
    private func deleteAllData() {
        let success = privacyManager.deleteUserData()
        if success {
            dismiss()
        }
    }
}

struct ConsentManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var privacyManager = PrivacyManager.shared
    
    var body: some View {
        NavigationView {
            List {
                ForEach(ConsentType.allCases, id: \.self) { consentType in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(consentType.displayName)
                                .font(.headline)
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { privacyManager.hasValidConsent(for: consentType) },
                                set: { hasConsent in
                                    if hasConsent {
                                        privacyManager.grantConsent(for: consentType)
                                    } else {
                                        privacyManager.revokeConsent(for: consentType)
                                    }
                                }
                            ))
                        }
                        
                        Text(consentType.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Consent Management")
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

#Preview {
    SecuritySettingsView()
}
