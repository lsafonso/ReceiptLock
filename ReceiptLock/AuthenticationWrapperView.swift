import SwiftUI
import LocalAuthentication

struct AuthenticationWrapperView<Content: View>: View {
    @StateObject private var biometricManager = BiometricAuthenticationManager.shared
    @State private var isAuthenticated = false
    @State private var showingAuthentication = false
    
    let content: Content
    let requireAuthentication: Bool
    
    init(requireAuthentication: Bool = true, @ViewBuilder content: () -> Content) {
        self.requireAuthentication = requireAuthentication
        self.content = content()
    }
    
    var body: some View {
        Group {
            if !requireAuthentication || isAuthenticated {
                content
            } else {
                authenticationPromptView
            }
        }
        .onAppear {
            if requireAuthentication && !isAuthenticated {
                showingAuthentication = true
            }
        }
        .sheet(isPresented: $showingAuthentication) {
            authenticationView
        }
    }
    
    private var authenticationPromptView: some View {
        VStack(spacing: 30) {
            Image(systemName: biometricManager.biometricType == .faceID ? "faceid" : "touchid")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Authentication Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Please authenticate to access this content")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Authenticate") {
                showingAuthentication = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var authenticationView: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: biometricManager.biometricType == .faceID ? "faceid" : "touchid")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Unlock ReceiptLock")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Use \(biometricManager.biometricTypeDescription) to access your receipts")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                if biometricManager.isBiometricAvailable {
                    Button("Use \(biometricManager.biometricTypeDescription)") {
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
    
    private func authenticate() {
        Task {
            let success = await biometricManager.authenticate()
            if success {
                await MainActor.run {
                    isAuthenticated = true
                    showingAuthentication = false
                }
            }
        }
    }
    
    private func authenticateWithPasscode() {
        Task {
            let success = await biometricManager.authenticate()
            if success {
                await MainActor.run {
                    isAuthenticated = true
                    showingAuthentication = false
                }
            }
        }
    }
}

// MARK: - Authentication State Manager

class AuthenticationStateManager: ObservableObject {
    static let shared = AuthenticationStateManager()
    
    @Published var isAuthenticated = false
    @Published var lastAuthenticationTime: Date?
    
    private let biometricManager = BiometricAuthenticationManager.shared
    private let privacyManager = PrivacyManager.shared
    
    private init() {
        // Check if authentication is required
        if privacyManager.privacySettings.biometricLockEnabled {
            checkAuthenticationStatus()
        }
    }
    
    func checkAuthenticationStatus() {
        let autoLockTimeout = privacyManager.privacySettings.autoLockTimeout
        
        if let lastAuth = lastAuthenticationTime {
            let timeSinceAuth = Date().timeIntervalSince(lastAuth)
            if timeSinceAuth > autoLockTimeout {
                isAuthenticated = false
            }
        }
    }
    
    func authenticate() async -> Bool {
        let success = await biometricManager.authenticate()
        
        if success {
            await MainActor.run {
                isAuthenticated = true
                lastAuthenticationTime = Date()
            }
        }
        
        return success
    }
    
    func logout() {
        isAuthenticated = false
        lastAuthenticationTime = nil
    }
    
    func startAutoLockTimer() {
        // Start a timer to automatically lock the app after the configured timeout
        let autoLockTimeout = privacyManager.privacySettings.autoLockTimeout
        
        DispatchQueue.main.asyncAfter(deadline: .now() + autoLockTimeout) {
            if self.isAuthenticated {
                self.logout()
            }
        }
    }
}

// MARK: - Usage Example

struct SecureContentView: View {
    var body: some View {
        AuthenticationWrapperView {
            VStack {
                Text("Secure Content")
                    .font(.title)
                Text("This content is protected by biometric authentication")
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    AuthenticationWrapperView {
        Text("Secure Content")
    }
}
