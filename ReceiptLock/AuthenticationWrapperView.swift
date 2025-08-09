import SwiftUI
import LocalAuthentication
import Combine

// MARK: - Authentication Wrapper View

struct AuthenticationWrapperView<Content: View>: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var showingAuthentication = false
    @State private var showingSecurityAlert = false
    @State private var securityAlertMessage = ""
    
    let content: Content
    let requireAuthentication: Bool
    let securityLevel: SecurityLevel
    let autoLockEnabled: Bool
    
    init(
        requireAuthentication: Bool = true,
        securityLevel: SecurityLevel = .high,
        autoLockEnabled: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.requireAuthentication = requireAuthentication
        self.securityLevel = securityLevel
        self.autoLockEnabled = autoLockEnabled
        self.content = content()
    }
    
    var body: some View {
        Group {
            if !requireAuthentication || authManager.isAuthenticated {
                content
                    .onReceive(authManager.$isAuthenticated) { isAuthenticated in
                        if isAuthenticated && autoLockEnabled {
                            authManager.startAutoLockTimer()
                        }
                    }
            } else {
                authenticationPromptView
            }
        }
        .onAppear {
            if requireAuthentication && !authManager.isAuthenticated {
                checkSecurityRequirements()
            }
        }
        .sheet(isPresented: $showingAuthentication) {
            authenticationView
        }
        .alert("Security Alert", isPresented: $showingSecurityAlert) {
            Button("OK") { }
        } message: {
            Text(securityAlertMessage)
        }
    }
    
    private var authenticationPromptView: some View {
        VStack(spacing: 30) {
            Image(systemName: authManager.biometricType == .faceID ? "faceid" : "touchid")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Authentication Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Please authenticate to access this content")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            VStack(spacing: 15) {
                Button("Authenticate") {
                    showingAuthentication = true
                }
                .buttonStyle(.borderedProminent)
                
                if securityLevel == .excellent {
                    Button("Security Settings") {
                        // Navigate to security settings
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
    }
    
    private var authenticationView: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: authManager.biometricType == .faceID ? "faceid" : "touchid")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Unlock ReceiptLock")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Use \(authManager.biometricTypeDescription) to access your receipts")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                if authManager.isBiometricAvailable {
                    Button("Use \(authManager.biometricTypeDescription)") {
                        authenticate()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Use Passcode") {
                        authenticateWithPasscode()
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button("Use Passcode") {
                        authenticateWithPasscode()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                if securityLevel == .excellent {
                    VStack(spacing: 10) {
                        Text("Security Level: \(securityLevel.rawValue)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(securityLevel.description)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Authentication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showingAuthentication = false
                    }
                }
            }
        }
    }
    
    private func checkSecurityRequirements() {
        let securityAudit = SecureStorageManager.shared.performSecurityAudit()
        
        if securityAudit.overallSecurityScore < 50 {
            securityAlertMessage = "Security configuration incomplete. Please review your security settings."
            showingSecurityAlert = true
        }
    }
    
    private func authenticate() {
        Task {
            let success = await authManager.authenticate()
            if success {
                await MainActor.run {
                    showingAuthentication = false
                }
            }
        }
    }
    
    private func authenticateWithPasscode() {
        Task {
            let success = await authManager.authenticateWithPasscode()
            if success {
                await MainActor.run {
                    showingAuthentication = false
                }
            }
        }
    }
}

// MARK: - Enhanced Authentication Manager

class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var isAuthenticated = false
    @Published var biometricType: LABiometryType = .none
    @Published var isBiometricAvailable = false
    @Published var authenticationMethod: AuthenticationMethod = .none
    @Published var lastAuthenticationTime: Date?
    @Published var failedAttempts = 0
    @Published var isLockedOut = false
    
    private let biometricManager = BiometricAuthenticationManager.shared
    private let privacyManager = PrivacyManager.shared
    private let secureStorage = SecureStorageManager.shared
    private let context = LAContext()
    private var autoLockTimer: Timer?
    private var lockoutTimer: Timer?
    
    private let maxFailedAttempts = 5
    private let lockoutDuration: TimeInterval = 300 // 5 minutes
    
    private init() {
        checkBiometricAvailability()
        loadAuthenticationState()
    }
    
    // MARK: - Biometric Availability Check
    
    func checkBiometricAvailability() {
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            isBiometricAvailable = true
            biometricType = context.biometryType
        } else {
            isBiometricAvailable = false
            biometricType = .none
            
            if let error = error {
                print("Biometric authentication not available: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Authentication Methods
    
    func authenticate() async -> Bool {
        guard !isLockedOut else {
            return false
        }
        
        let success = await biometricManager.authenticate()
        
        if success {
            await MainActor.run {
                self.handleSuccessfulAuthentication(.biometric)
            }
        } else {
            await MainActor.run {
                self.handleFailedAuthentication()
            }
        }
        
        return success
    }
    
    func authenticateWithPasscode() async -> Bool {
        guard !isLockedOut else {
            return false
        }
        
        let success = await biometricManager.authenticateWithPasscode()
        
        if success {
            await MainActor.run {
                self.handleSuccessfulAuthentication(.passcode)
            }
        } else {
            await MainActor.run {
                self.handleFailedAuthentication()
            }
        }
        
        return success
    }
    
    // MARK: - Authentication State Management
    
    private func handleSuccessfulAuthentication(_ method: AuthenticationMethod) {
        isAuthenticated = true
        authenticationMethod = method
        lastAuthenticationTime = Date()
        failedAttempts = 0
        isLockedOut = false
        
        // Cancel any existing lockout timer
        lockoutTimer?.invalidate()
        lockoutTimer = nil
        
        // Start auto-lock timer if enabled
        if privacyManager.privacySettings.biometricLockEnabled {
            startAutoLockTimer()
        }
        
        // Log successful authentication
        logAuthenticationEvent(success: true, method: method)
        
        // Save authentication state
        saveAuthenticationState()
    }
    
    private func handleFailedAuthentication() {
        failedAttempts += 1
        
        if failedAttempts >= maxFailedAttempts {
            isLockedOut = true
            startLockoutTimer()
        }
        
        // Log failed authentication
        logAuthenticationEvent(success: false, method: authenticationMethod)
        
        // Save authentication state
        saveAuthenticationState()
    }
    
    private func startLockoutTimer() {
        lockoutTimer?.invalidate()
        lockoutTimer = Timer.scheduledTimer(withTimeInterval: lockoutDuration, repeats: false) { _ in
            DispatchQueue.main.async {
                self.isLockedOut = false
                self.failedAttempts = 0
                self.saveAuthenticationState()
            }
        }
    }
    
    // MARK: - Auto-Lock Management
    
    func startAutoLockTimer() {
        autoLockTimer?.invalidate()
        
        let autoLockTimeout = privacyManager.privacySettings.autoLockTimeout
        
        autoLockTimer = Timer.scheduledTimer(withTimeInterval: autoLockTimeout, repeats: false) { _ in
            DispatchQueue.main.async {
                self.logout()
            }
        }
    }
    
    func stopAutoLockTimer() {
        autoLockTimer?.invalidate()
        autoLockTimer = nil
    }
    
    // MARK: - Session Management
    
    func logout() {
        isAuthenticated = false
        authenticationMethod = .none
        lastAuthenticationTime = nil
        
        stopAutoLockTimer()
        
        // Clear sensitive data from memory
        clearSensitiveData()
        
        // Log logout event
        logAuthenticationEvent(success: true, method: .logout)
        
        // Save authentication state
        saveAuthenticationState()
    }
    
    func refreshAuthentication() {
        guard isAuthenticated else { return }
        
        // Reset auto-lock timer
        if privacyManager.privacySettings.biometricLockEnabled {
            startAutoLockTimer()
        }
        
        // Update last authentication time
        lastAuthenticationTime = Date()
        saveAuthenticationState()
    }
    
    // MARK: - Security Validation
    
    func validateSecurityRequirements() -> SecurityValidationResult {
        var result = SecurityValidationResult()
        
        // Check biometric availability
        result.biometricAvailable = isBiometricAvailable
        
        // Check privacy settings
        result.privacySettingsConfigured = privacyManager.privacySettings.biometricLockEnabled
        
        // Check encryption
        let securityAudit = secureStorage.performSecurityAudit()
        result.encryptionEnabled = securityAudit.encryptionKeysPresent
        
        // Check user consent
        result.userConsentValid = privacyManager.hasValidConsent(for: .dataProcessing)
        
        // Calculate overall security score
        result.calculateSecurityScore()
        
        return result
    }
    
    // MARK: - Private Methods
    
    private func clearSensitiveData() {
        // Clear any sensitive data that might be stored in memory
        // This is a placeholder for actual implementation
    }
    
    private func logAuthenticationEvent(success: Bool, method: AuthenticationMethod) {
        // Log authentication events for security auditing
        let event = AuthenticationEvent(
            timestamp: Date(),
            success: success,
            method: method,
            deviceInfo: getDeviceInfo()
        )
        
        // Save to secure storage for audit purposes
        do {
            let eventData = try JSONEncoder().encode(event)
            try secureStorage.storeSecureData(eventData, forKey: "AuthEvent_\(Date().timeIntervalSince1970)")
        } catch {
            print("Failed to log authentication event: \(error)")
        }
    }
    
    private func getDeviceInfo() -> String {
        let device = UIDevice.current
        return "\(device.model) - \(device.systemName) \(device.systemVersion)"
    }
    
    private func loadAuthenticationState() {
        // Load authentication state from secure storage
        do {
            if let lastAuthData = try? secureStorage.retrieveSecureData(forKey: "LastAuthenticationTime"),
               let lastAuth = try? JSONDecoder().decode(Date.self, from: lastAuthData) {
                lastAuthenticationTime = lastAuth
            }
            
            if let failedAttemptsData = try? secureStorage.retrieveSecureData(forKey: "FailedAttempts"),
               let failedAttempts = try? JSONDecoder().decode(Int.self, from: failedAttemptsData) {
                self.failedAttempts = failedAttempts
            }
        } catch {
            print("Failed to load authentication state: \(error)")
        }
    }
    
    private func saveAuthenticationState() {
        // Save authentication state to secure storage
        do {
            if let lastAuth = lastAuthenticationTime {
                let lastAuthData = try JSONEncoder().encode(lastAuth)
                try secureStorage.storeSecureData(lastAuthData, forKey: "LastAuthenticationTime")
            }
            
            let failedAttemptsData = try JSONEncoder().encode(failedAttempts)
            try secureStorage.storeSecureData(failedAttemptsData, forKey: "FailedAttempts")
        } catch {
            print("Failed to save authentication state: \(error)")
        }
    }
    
    // MARK: - Computed Properties
    
    var biometricTypeDescription: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .none:
            return "Passcode"
        @unknown default:
            return "Biometric"
        }
    }
    
    var isSessionValid: Bool {
        guard isAuthenticated, let lastAuth = lastAuthenticationTime else {
            return false
        }
        
        let autoLockTimeout = privacyManager.privacySettings.autoLockTimeout
        let timeSinceAuth = Date().timeIntervalSince(lastAuth)
        
        return timeSinceAuth < autoLockTimeout
    }
}

// MARK: - Supporting Types

enum AuthenticationMethod: String, Codable, CaseIterable {
    case biometric = "biometric"
    case passcode = "passcode"
    case logout = "logout"
    case none = "none"
    
    var displayName: String {
        switch self {
        case .biometric:
            return "Biometric"
        case .passcode:
            return "Passcode"
        case .logout:
            return "Logout"
        case .none:
            return "None"
        }
    }
}

struct SecurityValidationResult {
    var biometricAvailable: Bool = false
    var privacySettingsConfigured: Bool = false
    var encryptionEnabled: Bool = false
    var userConsentValid: Bool = false
    var securityScore: Int = 0
    
    mutating func calculateSecurityScore() {
        var score = 0
        
        if biometricAvailable { score += 25 }
        if privacySettingsConfigured { score += 25 }
        if encryptionEnabled { score += 25 }
        if userConsentValid { score += 25 }
        
        securityScore = score
    }
    
    var securityLevel: SecurityLevel {
        switch securityScore {
        case 0...25:
            return .low
        case 26...50:
            return .medium
        case 51...75:
            return .high
        case 76...100:
            return .excellent
        default:
            return .low
        }
    }
}

struct AuthenticationEvent: Codable {
    let timestamp: Date
    let success: Bool
    let method: AuthenticationMethod
    let deviceInfo: String
}

// MARK: - Usage Examples

struct SecureContentView: View {
    var body: some View {
        AuthenticationWrapperView(
            requireAuthentication: true,
            securityLevel: .excellent,
            autoLockEnabled: true
        ) {
            VStack {
                Text("Secure Content")
                    .font(.title)
                Text("This content is protected by biometric authentication")
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct StandardContentView: View {
    var body: some View {
        AuthenticationWrapperView(
            requireAuthentication: true,
            securityLevel: .high,
            autoLockEnabled: true
        ) {
            VStack {
                Text("Standard Content")
                    .font(.title)
                Text("This content requires standard authentication")
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct PublicContentView: View {
    var body: some View {
        AuthenticationWrapperView(
            requireAuthentication: false,
            securityLevel: .low,
            autoLockEnabled: false
        ) {
            VStack {
                Text("Public Content")
                    .font(.title)
                Text("This content is publicly accessible")
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SecureContentView()
        StandardContentView()
        PublicContentView()
    }
}
