import Foundation
import SwiftUI

class PrivacyManager: ObservableObject {
    static let shared = PrivacyManager()
    
    @Published var privacySettings = PrivacySettings()
    @Published var dataRetentionPolicy = DataRetentionPolicy()
    @Published var userConsent = UserConsent()
    
    private let keychain = KeychainWrapper.standard
    private let userDefaults = UserDefaults.standard
    
    private init() {
        loadPrivacySettings()
        loadDataRetentionPolicy()
        loadUserConsent()
    }
    
    // MARK: - Privacy Settings Management
    
    func updatePrivacySettings(_ settings: PrivacySettings) {
        privacySettings = settings
        savePrivacySettings()
    }
    
    func updateDataRetentionPolicy(_ policy: DataRetentionPolicy) {
        dataRetentionPolicy = policy
        saveDataRetentionPolicy()
    }
    
    func updateUserConsent(_ consent: UserConsent) {
        userConsent = consent
        saveUserConsent()
    }
    
    // MARK: - Data Retention
    
    func shouldRetainData(_ dataType: DataType, createdAt: Date) -> Bool {
        let retentionPeriod = dataRetentionPolicy.retentionPeriod(for: dataType)
        let expirationDate = Calendar.current.date(byAdding: retentionPeriod, to: createdAt) ?? Date()
        
        return Date() < expirationDate
    }
    
    func getDataExpirationDate(for dataType: DataType, createdAt: Date) -> Date? {
        let retentionPeriod = dataRetentionPolicy.retentionPeriod(for: dataType)
        return Calendar.current.date(byAdding: retentionPeriod, to: createdAt)
    }
    
    func cleanupExpiredData() {
        // This would be called periodically to clean up expired data
        // Implementation depends on your data storage mechanism
        print("Cleaning up expired data based on retention policy")
    }
    
    // MARK: - GDPR Compliance
    
    func exportUserData() -> UserDataExport {
        // Export all user data in a structured format
        return UserDataExport(
            personalInfo: exportPersonalInfo(),
            receipts: exportReceipts(),
            settings: exportSettings(),
            exportDate: Date(),
            exportVersion: "1.0"
        )
    }
    
    func deleteUserData() -> Bool {
        // Delete all user data and reset the app
        do {
            // Clear Core Data
            try clearCoreData()
            
            // Clear images
            clearStoredImages()
            
            // Clear settings
            clearUserSettings()
            
            // Clear keychain
            _ = keychain.clearAll()
            
            // Reset privacy settings
            resetPrivacySettings()
            
            return true
        } catch {
            print("Error deleting user data: \(error)")
            return false
        }
    }
    
    func anonymizeUserData() -> Bool {
        // Anonymize personal data while keeping receipt information
        
        // Anonymize personal information
        anonymizePersonalInfo()
        
        // Keep receipt data but remove personal identifiers
        anonymizeReceipts()
        
        return true
    }
    
    // MARK: - Privacy Controls
    
    func enableDataSharing(_ enabled: Bool) {
        privacySettings.dataSharingEnabled = enabled
        savePrivacySettings()
    }
    
    func enableAnalytics(_ enabled: Bool) {
        privacySettings.analyticsEnabled = enabled
        saveUserConsent()
    }
    
    func enableCrashReporting(_ enabled: Bool) {
        privacySettings.crashReportingEnabled = enabled
        saveUserConsent()
    }
    
    // MARK: - Consent Management
    
    func hasValidConsent(for consentType: ConsentType) -> Bool {
        guard let consent = userConsent.consents[consentType] else {
            return false
        }
        
        // Check if consent is still valid
        let expirationDate = Calendar.current.date(byAdding: .year, value: 1, to: consent.grantedDate) ?? Date()
        return Date() < expirationDate
    }
    
    func grantConsent(for consentType: ConsentType) {
        let consent = ConsentRecord(
            granted: true,
            grantedDate: Date(),
            consentVersion: getCurrentConsentVersion()
        )
        
        userConsent.consents[consentType] = consent
        saveUserConsent()
    }
    
    func revokeConsent(for consentType: ConsentType) {
        userConsent.consents.removeValue(forKey: consentType)
        saveUserConsent()
    }
    
    // MARK: - Private Methods
    
    private func loadPrivacySettings() {
        if let data = userDefaults.data(forKey: "PrivacySettings"),
           let settings = try? JSONDecoder().decode(PrivacySettings.self, from: data) {
            privacySettings = settings
        }
    }
    
    private func savePrivacySettings() {
        if let data = try? JSONEncoder().encode(privacySettings) {
            userDefaults.set(data, forKey: "PrivacySettings")
        }
    }
    
    private func loadDataRetentionPolicy() {
        if let data = userDefaults.data(forKey: "DataRetentionPolicy"),
           let policy = try? JSONDecoder().decode(DataRetentionPolicy.self, from: data) {
            dataRetentionPolicy = policy
        }
    }
    
    private func saveDataRetentionPolicy() {
        if let data = try? JSONEncoder().encode(dataRetentionPolicy) {
            userDefaults.set(data, forKey: "DataRetentionPolicy")
        }
    }
    
    private func loadUserConsent() {
        if let data = userDefaults.data(forKey: "UserConsent"),
           let consent = try? JSONDecoder().decode(UserConsent.self, from: data) {
            userConsent = consent
        }
    }
    
    private func saveUserConsent() {
        if let data = try? JSONEncoder().encode(userConsent) {
            userDefaults.set(data, forKey: "UserConsent")
        }
    }
    
    private func getCurrentConsentVersion() -> String {
        return "1.0" // Update this when consent terms change
    }
    
    private func clearCoreData() throws {
        // Implementation depends on your Core Data setup
        // This is a placeholder for the actual implementation
    }
    
    private func clearStoredImages() {
        // Implementation depends on your image storage
        // This is a placeholder for the actual implementation
    }
    
    private func clearUserSettings() {
        // Clear UserDefaults
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
    }
    
    private func resetPrivacySettings() {
        privacySettings = PrivacySettings()
        dataRetentionPolicy = DataRetentionPolicy()
        userConsent = UserConsent()
    }
    
    private func exportPersonalInfo() -> PersonalInfoExport {
        // Export personal information
        let profileManager = UserProfileManager.shared
        return PersonalInfoExport(
            name: profileManager.currentProfile.name,
            email: "", // UserProfile doesn't have email field
            createdAt: Date(), // UserProfile doesn't have createdAt field
            lastUpdated: Date() // UserProfile doesn't have updatedAt field
        )
    }
    
    private func exportReceipts() -> [ReceiptExport] {
        // Export receipt data
        // This would need to be implemented based on your Core Data model
        return []
    }
    
    private func exportSettings() -> SettingsExport {
        // Export user settings
        return SettingsExport(
            theme: privacySettings.theme,
            notifications: privacySettings.notificationsEnabled,
            dataSharing: privacySettings.dataSharingEnabled,
            analytics: privacySettings.analyticsEnabled,
            crashReporting: privacySettings.crashReportingEnabled
        )
    }
    
    private func anonymizePersonalInfo() {
        // Anonymize personal information
        let profileManager = UserProfileManager.shared
        profileManager.updateName("Anonymous User")
        // Note: UserProfile doesn't have email field
    }
    
    private func anonymizeReceipts() {
        // Anonymize receipt data
        // This would need to be implemented based on your Core Data model
    }
}

// MARK: - Data Models

enum RetentionPeriod: String, Codable, CaseIterable {
    case day = "day"
    case week = "week"
    case month = "month"
    case year = "year"
    
    var calendarComponent: Calendar.Component {
        switch self {
        case .day: return .day
        case .week: return .weekOfYear
        case .month: return .month
        case .year: return .year
        }
    }
    
    var displayName: String {
        switch self {
        case .day: return "Day"
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        }
    }
}

struct PrivacySettings: Codable {
    var theme: ThemeMode = .system
    var notificationsEnabled: Bool = true
    var dataSharingEnabled: Bool = false
    var analyticsEnabled: Bool = false
    var crashReportingEnabled: Bool = false
    var biometricLockEnabled: Bool = true
    var autoLockTimeout: TimeInterval = 300 // 5 minutes
}

struct DataRetentionPolicy: Codable {
    var receiptRetentionPeriod: RetentionPeriod = .year
    var receiptRetentionValue: Int = 7 // 7 years
    var imageRetentionPeriod: RetentionPeriod = .year
    var imageRetentionValue: Int = 7 // 7 years
    var logRetentionPeriod: RetentionPeriod = .month
    var logRetentionValue: Int = 3 // 3 months
    
    func retentionPeriod(for dataType: DataType) -> DateComponents {
        switch dataType {
        case .receipt:
            return createDateComponents(for: receiptRetentionPeriod, value: receiptRetentionValue)
        case .image:
            return createDateComponents(for: imageRetentionPeriod, value: imageRetentionValue)
        case .log:
            return createDateComponents(for: logRetentionPeriod, value: logRetentionValue)
        }
    }
    
    private func createDateComponents(for period: RetentionPeriod, value: Int) -> DateComponents {
        switch period {
        case .day:
            return DateComponents(day: value)
        case .week:
            return DateComponents(weekOfYear: value)
        case .month:
            return DateComponents(month: value)
        case .year:
            return DateComponents(year: value)
        }
    }
}

struct UserConsent: Codable {
    var consents: [ConsentType: ConsentRecord] = [:]
    var lastUpdated: Date = Date()
}

struct ConsentRecord: Codable {
    let granted: Bool
    let grantedDate: Date
    let consentVersion: String
}

enum ConsentType: String, Codable, CaseIterable {
    case dataProcessing = "data_processing"
    case analytics = "analytics"
    case crashReporting = "crash_reporting"
    case dataSharing = "data_sharing"
    case marketing = "marketing"
    
    var displayName: String {
        switch self {
        case .dataProcessing:
            return "Data Processing"
        case .analytics:
            return "Analytics"
        case .crashReporting:
            return "Crash Reporting"
        case .dataSharing:
            return "Data Sharing"
        case .marketing:
            return "Marketing Communications"
        }
    }
    
    var description: String {
        switch self {
        case .dataProcessing:
            return "Process your data to provide app functionality"
        case .analytics:
            return "Collect anonymous usage data to improve the app"
        case .crashReporting:
            return "Collect crash reports to fix issues"
        case .dataSharing:
            return "Share data with third-party services"
        case .marketing:
            return "Send marketing communications"
        }
    }
}

enum DataType: String, CaseIterable {
    case receipt = "receipt"
    case image = "image"
    case log = "log"
}



// MARK: - Export Models

struct UserDataExport: Codable {
    let personalInfo: PersonalInfoExport
    let receipts: [ReceiptExport]
    let settings: SettingsExport
    let exportDate: Date
    let exportVersion: String
}

struct PersonalInfoExport: Codable {
    let name: String
    let email: String
    let createdAt: Date
    let lastUpdated: Date
}

struct ReceiptExport: Codable {
    let id: String
    let title: String
    let store: String
    let purchaseDate: Date
    let price: Double
    let warrantyMonths: Int16
    let expiryDate: Date?
    let createdAt: Date
    let updatedAt: Date
}

struct SettingsExport: Codable {
    let theme: ThemeMode
    let notifications: Bool
    let dataSharing: Bool
    let analytics: Bool
    let crashReporting: Bool
}
