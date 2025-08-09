import Foundation
import LocalAuthentication
import SwiftUI

class BiometricAuthenticationManager: ObservableObject {
    static let shared = BiometricAuthenticationManager()
    
    @Published var isAuthenticated = false
    @Published var biometricType: LABiometryType = .none
    @Published var isBiometricAvailable = false
    
    private let context = LAContext()
    private let reason = "Authenticate to access your receipts"
    
    private init() {
        checkBiometricAvailability()
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
    
    // MARK: - Authentication
    
    func authenticate() async -> Bool {
        guard isBiometricAvailable else {
            // Fallback to device passcode
            return await authenticateWithPasscode()
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            await MainActor.run {
                self.isAuthenticated = success
            }
            
            return success
        } catch {
            print("Biometric authentication failed: \(error.localizedDescription)")
            
            // Fallback to passcode if biometric fails
            if let laError = error as? LAError {
                switch laError.code {
                case .userFallback, .userCancel, .systemCancel:
                    return await authenticateWithPasscode()
                default:
                    break
                }
            }
            
            return false
        }
    }
    
    private func authenticateWithPasscode() async -> Bool {
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Enter your device passcode to continue"
            )
            
            await MainActor.run {
                self.isAuthenticated = success
            }
            
            return success
        } catch {
            print("Passcode authentication failed: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Logout
    
    func logout() {
        isAuthenticated = false
    }
    
    // MARK: - Biometric Type Description
    
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
    
    // MARK: - Settings Check
    
    func checkBiometricSettings() -> BiometricSettingsStatus {
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return .available
        }
        
        if let error = error as? LAError {
            switch error.code {
            case .biometryNotEnrolled:
                return .notEnrolled
            case .biometryNotAvailable:
                return .notAvailable
            case .passcodeNotSet:
                return .passcodeNotSet
            default:
                return .notAvailable
            }
        }
        
        return .notAvailable
    }
}

enum BiometricSettingsStatus {
    case available
    case notEnrolled
    case notAvailable
    case passcodeNotSet
    
    var description: String {
        switch self {
        case .available:
            return "Biometric authentication is available"
        case .notEnrolled:
            return "No biometric data enrolled"
        case .notAvailable:
            return "Biometric authentication not available on this device"
        case .passcodeNotSet:
            return "Device passcode not set"
        }
    }
    
    var requiresAction: Bool {
        switch self {
        case .available:
            return false
        case .notEnrolled, .notAvailable, .passcodeNotSet:
            return true
        }
    }
}
