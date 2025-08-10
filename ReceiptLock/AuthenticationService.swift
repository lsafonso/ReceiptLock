import Foundation
import SwiftUI
import Combine

// MARK: - Authentication Service

class AuthenticationService: ObservableObject {
    static let shared = AuthenticationService()
    
    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    @Published var authenticationStatus: AuthenticationStatus = .notAuthenticated
    
    private let authManager = AuthenticationManager.shared
    private let privacyManager = PrivacyManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupBindings()
        checkInitialAuthenticationStatus()
    }
    
    // MARK: - Public Methods
    
    /// Check if user is currently authenticated
    var isUserAuthenticated: Bool {
        return authManager.isAuthenticated && authManager.isSessionValid
    }
    
    /// Get the current security level
    var currentSecurityLevel: SecurityLevel {
        let validation = authManager.validateSecurityRequirements()
        return validation.securityLevel
    }
    
    /// Check if authentication is required for a specific feature
    func requiresAuthentication(for feature: SecurityFeature) -> Bool {
        switch feature {
        case .receipts:
            return privacyManager.privacySettings.biometricLockEnabled
        case .settings:
            return false
        case .profile:
            return privacyManager.privacySettings.biometricLockEnabled
        case .backup:
            return privacyManager.privacySettings.biometricLockEnabled
        case .export:
            return privacyManager.privacySettings.biometricLockEnabled
        }
    }
    
    /// Authenticate user for a specific feature
    func authenticate(for feature: SecurityFeature) async -> Bool {
        guard requiresAuthentication(for: feature) else {
            return true
        }
        
        return await authManager.authenticate()
    }
    
    /// Check if user has permission to access a specific feature
    func hasPermission(for feature: SecurityFeature) -> Bool {
        if !requiresAuthentication(for: feature) {
            return true
        }
        
        return isUserAuthenticated
    }
    
    /// Logout user and clear sensitive data
    func logout() {
        authManager.logout()
        currentUser = nil
        authenticationStatus = .notAuthenticated
    }
    
    /// Refresh authentication session
    func refreshSession() {
        guard isUserAuthenticated else { return }
        authManager.refreshAuthentication()
    }
    
    /// Get authentication status description
    func getAuthenticationStatusDescription() -> String {
        switch authenticationStatus {
        case .notAuthenticated:
            return "Not authenticated"
        case .authenticated:
            return "Authenticated"
        case .expired:
            return "Session expired"
        case .locked:
            return "Account locked"
        case .requiresSetup:
            return "Authentication setup required"
        }
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        authManager.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                self?.updateAuthenticationStatus(isAuthenticated: isAuthenticated)
            }
            .store(in: &cancellables)
        
        authManager.$isLockedOut
            .sink { [weak self] isLockedOut in
                if isLockedOut {
                    self?.authenticationStatus = .locked
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkInitialAuthenticationStatus() {
        if authManager.isAuthenticated {
            authenticationStatus = .authenticated
        } else {
            authenticationStatus = .notAuthenticated
        }
    }
    
    private func updateAuthenticationStatus(isAuthenticated: Bool) {
        if isAuthenticated {
            if authManager.isSessionValid {
                authenticationStatus = .authenticated
            } else {
                authenticationStatus = .expired
            }
        } else {
            authenticationStatus = .notAuthenticated
        }
    }
}

// MARK: - Supporting Types

enum AuthenticationStatus: String, CaseIterable {
    case notAuthenticated = "Not Authenticated"
    case authenticated = "Authenticated"
    case expired = "Session Expired"
    case locked = "Account Locked"
    case requiresSetup = "Setup Required"
    
    var description: String {
        switch self {
        case .notAuthenticated:
            return "User is not currently authenticated"
        case .authenticated:
            return "User is authenticated and session is valid"
        case .expired:
            return "User session has expired and requires re-authentication"
        case .locked:
            return "Account is temporarily locked due to security concerns"
        case .requiresSetup:
            return "Authentication setup is required before use"
        }
    }
    
    var color: String {
        switch self {
        case .notAuthenticated:
            return "red"
        case .authenticated:
            return "green"
        case .expired:
            return "muted-orange"
        case .locked:
            return "red"
        case .requiresSetup:
            return "yellow"
        }
    }
    
    var icon: String {
        switch self {
        case .notAuthenticated:
            return "lock.slash"
        case .authenticated:
            return "lock.open"
        case .expired:
            return "clock"
        case .locked:
            return "lock.shield"
        case .requiresSetup:
            return "gear"
        }
    }
}

enum SecurityFeature: String, CaseIterable {
    case receipts = "receipts"
    case settings = "settings"
    case profile = "profile"
    case backup = "backup"
    case export = "export"
    
    var displayName: String {
        switch self {
        case .receipts:
            return "Receipts"
        case .settings:
            return "Settings"
        case .profile:
            return "Profile"
        case .backup:
            return "Backup"
        case .export:
            return "Data Export"
        }
    }
    
    var description: String {
        switch self {
        case .receipts:
            return "Access to receipt management and viewing"
        case .settings:
            return "Access to app settings and configuration"
        case .profile:
            return "Access to user profile and preferences"
        case .backup:
            return "Access to backup and restore functionality"
        case .export:
            return "Access to data export functionality"
        }
    }
    
    var requiresHighSecurity: Bool {
        switch self {
        case .receipts, .backup, .export:
            return true
        case .settings, .profile:
            return false
        }
    }
}

// MARK: - Authentication View Modifier

struct RequireAuthentication: ViewModifier {
    let feature: SecurityFeature
    let fallbackView: (() -> AnyView)?
    
    @StateObject private var authService = AuthenticationService.shared
    @State private var showingAuthentication = false
    
    init(_ feature: SecurityFeature, fallbackView: (() -> AnyView)? = nil) {
        self.feature = feature
        self.fallbackView = fallbackView
    }
    
    func body(content: Content) -> some View {
        Group {
            if authService.hasPermission(for: feature) {
                content
            } else {
                fallbackView?() ?? AnyView(
                    AuthenticationPromptView(feature: feature) {
                        showingAuthentication = true
                    }
                )
            }
        }
        .sheet(isPresented: $showingAuthentication) {
            AuthenticationView(feature: feature)
        }
    }
}

// MARK: - Authentication Prompt View

struct AuthenticationPromptView: View {
    let feature: SecurityFeature
    let onAuthenticate: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "lock.shield")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Authentication Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Please authenticate to access \(feature.displayName.lowercased())")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Authenticate") {
                onAuthenticate()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Authentication View

struct AuthenticationView: View {
    let feature: SecurityFeature
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthenticationService.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Unlock \(feature.displayName)")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Use biometric authentication or passcode to access \(feature.displayName.lowercased())")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 15) {
                    Button("Use Biometric") {
                        authenticate()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Use Passcode") {
                        authenticateWithPasscode()
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Authentication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func authenticate() {
        Task {
            let success = await authService.authenticate(for: feature)
            if success {
                await MainActor.run {
                    dismiss()
                }
            }
        }
    }
    
    private func authenticateWithPasscode() {
        Task {
            let success = await authService.authenticate(for: feature)
            if success {
                await MainActor.run {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Require authentication for a specific feature
    func requireAuthentication(_ feature: SecurityFeature) -> some View {
        self.modifier(RequireAuthentication(feature))
    }
    
    /// Require authentication with custom fallback view
    func requireAuthentication(_ feature: SecurityFeature, fallbackView: @escaping () -> AnyView) -> some View {
        self.modifier(RequireAuthentication(feature, fallbackView: fallbackView))
    }
}

// MARK: - Usage Examples

struct SecureReceiptView: View {
    var body: some View {
        VStack {
            Text("Secure Receipt Content")
                .font(.title)
            Text("This content requires authentication")
                .foregroundColor(.secondary)
        }
        .requireAuthentication(.receipts)
    }
}

struct PublicSettingsView: View {
    var body: some View {
        VStack {
            Text("Public Settings Content")
                .font(.title)
            Text("This content is publicly accessible")
                .foregroundColor(.secondary)
        }
        .requireAuthentication(.settings)
    }
}

#Preview {
    VStack(spacing: 20) {
        SecureReceiptView()
        PublicSettingsView()
    }
}
