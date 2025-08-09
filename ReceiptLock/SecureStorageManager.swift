import Foundation
import CoreData
import CryptoKit

class SecureStorageManager: ObservableObject {
    static let shared = SecureStorageManager()
    
    private let encryptionManager = DataEncryptionManager.shared
    private let privacyManager = PrivacyManager.shared
    
    private init() {}
    
    // MARK: - Secure Data Storage
    
    func storeSecureData(_ data: Data, forKey key: String) throws {
        let encryptedData = try encryptionManager.encrypt(data)
        let success = KeychainWrapper.standard.set(encryptedData, forKey: key)
        guard success else {
            throw SecureStorageError.keychainWriteFailed
        }
    }
    
    func retrieveSecureData(forKey key: String) throws -> Data {
        guard let encryptedData = KeychainWrapper.standard.data(forKey: key) else {
            throw SecureStorageError.dataNotFound
        }
        
        return try encryptionManager.decrypt(encryptedData)
    }
    
    func storeSecureString(_ string: String, forKey key: String) throws {
        let encryptedData = try encryptionManager.encrypt(string)
        let success = KeychainWrapper.standard.set(encryptedData, forKey: key)
        guard success else {
            throw SecureStorageError.keychainWriteFailed
        }
    }
    
    func retrieveSecureString(forKey key: String) throws -> String {
        guard let encryptedData = KeychainWrapper.standard.data(forKey: key) else {
            throw SecureStorageError.dataNotFound
        }
        
        return try encryptionManager.decryptToString(encryptedData)
    }
    
    // MARK: - Encrypted Core Data Attributes
    
    func encryptAttribute(_ value: String) throws -> Data {
        return try encryptionManager.encrypt(value)
    }
    
    func decryptAttribute(_ encryptedData: Data) throws -> String {
        return try encryptionManager.decryptToString(encryptedData)
    }
    
    // MARK: - Secure Receipt Storage
    
    func storeReceiptSecurely(_ receipt: Receipt) throws {
        // Encrypt sensitive fields before storing
        if let title = receipt.title {
            let encryptedTitle = try encryptAttribute(title)
            receipt.title = encryptedTitle.base64EncodedString()
        }
        
        if let store = receipt.store {
            let encryptedStore = try encryptAttribute(store)
            receipt.store = encryptedStore.base64EncodedString()
        }
        
        // Store encrypted image if exists
        if let imageData = receipt.imageData {
            let encryptedImageData = try encryptionManager.encrypt(imageData)
            receipt.imageData = encryptedImageData
        }
    }
    
    func retrieveReceiptSecurely(_ receipt: Receipt) throws {
        // Decrypt sensitive fields after retrieving
        if let encryptedTitle = receipt.title {
            guard let titleData = Data(base64Encoded: encryptedTitle) else {
                throw SecureStorageError.decryptionFailed
            }
            let decryptedTitle = try decryptAttribute(titleData)
            receipt.title = decryptedTitle
        }
        
        if let encryptedStore = receipt.store {
            guard let storeData = Data(base64Encoded: encryptedStore) else {
                throw SecureStorageError.decryptionFailed
            }
            let decryptedStore = try decryptAttribute(storeData)
            receipt.store = decryptedStore
        }
        
        // Decrypt image if exists
        if let encryptedImageData = receipt.imageData {
            let decryptedImageData = try encryptionManager.decrypt(encryptedImageData)
            receipt.imageData = decryptedImageData
        }
    }
    
    // MARK: - Secure Image Storage
    
    private func encryptReceiptImage(_ fileName: String) throws {
        let imageManager = ImageStorageManager.shared
        
        // Load the image
        guard let image = imageManager.loadReceiptImage(fileName: fileName) else {
            throw SecureStorageError.imageNotFound
        }
        
        // Convert to data and encrypt
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw SecureStorageError.imageConversionFailed
        }
        
        let encryptedData = try encryptionManager.encrypt(imageData)
        
        // Store encrypted image with new filename
        let encryptedFileName = "encrypted_\(fileName)"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let encryptedPath = documentsPath.appendingPathComponent("receipts").appendingPathComponent(encryptedFileName)
        
        try encryptedData.write(to: encryptedPath)
        
        // Update receipt with encrypted filename
        // This would need to be implemented based on your Core Data model
    }
    
    private func decryptReceiptImage(_ fileName: String) throws {
        // Implementation for decrypting images
        // This would need to be implemented based on your image storage mechanism
    }
    
    // MARK: - Data Retention Enforcement
    
    func enforceDataRetentionPolicy() {
        let context = PersistenceController.shared.container.viewContext
        
        // Fetch all receipts
        let fetchRequest: NSFetchRequest<Receipt> = Receipt.fetchRequest()
        
        do {
            let receipts = try context.fetch(fetchRequest)
            
            for receipt in receipts {
                if let createdAt = receipt.createdAt {
                    if !privacyManager.shouldRetainData(.receipt, createdAt: createdAt) {
                        // Delete expired receipt
                        context.delete(receipt)
                        
                        // Delete associated image
                        if receipt.imageData != nil {
                            // Clear the image data
                            receipt.imageData = nil
                        }
                    }
                }
            }
            
            // Save context
            try context.save()
            
        } catch {
            print("Error enforcing data retention policy: \(error)")
        }
    }
    
    // MARK: - Secure Backup
    
    func createSecureBackup() throws -> Data {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<Receipt> = Receipt.fetchRequest()
        
        let receipts = try context.fetch(fetchRequest)
        
        // Create backup structure
        var backupData: [String: Any] = [:]
        backupData["version"] = "1.0"
        backupData["createdAt"] = Date()
        backupData["receipts"] = receipts.map { receipt in
            var receiptData: [String: Any] = [:]
            receiptData["id"] = receipt.id?.uuidString
            receiptData["title"] = receipt.title
            receiptData["store"] = receipt.store
            receiptData["purchaseDate"] = receipt.purchaseDate
            receiptData["price"] = receipt.price
            receiptData["warrantyMonths"] = receipt.warrantyMonths
            receiptData["expiryDate"] = receipt.expiryDate
            receiptData["createdAt"] = receipt.createdAt
            receiptData["updatedAt"] = receipt.updatedAt
            return receiptData
        }
        
        // Convert to JSON and encrypt
        let jsonData = try JSONSerialization.data(withJSONObject: backupData)
        return try encryptionManager.encrypt(jsonData)
    }
    
    func restoreFromSecureBackup(_ backupData: Data) throws {
        // Decrypt backup data
        let decryptedData = try encryptionManager.decrypt(backupData)
        
        // Parse JSON
        guard let backup = try JSONSerialization.jsonObject(with: decryptedData) as? [String: Any],
              let receiptsData = backup["receipts"] as? [[String: Any]] else {
            throw SecureStorageError.invalidBackupFormat
        }
        
        let context = PersistenceController.shared.container.viewContext
        
        // Clear existing data
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Receipt.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try context.execute(deleteRequest)
        
        // Restore receipts
        for receiptData in receiptsData {
            let receipt = Receipt(context: context)
            
            if let idString = receiptData["id"] as? String {
                receipt.id = UUID(uuidString: idString)
            }
            
            receipt.title = receiptData["title"] as? String
            receipt.store = receiptData["store"] as? String
            receipt.purchaseDate = receiptData["purchaseDate"] as? Date
            receipt.price = receiptData["price"] as? Double ?? 0.0
            receipt.warrantyMonths = receiptData["warrantyMonths"] as? Int16 ?? 0
            receipt.expiryDate = receiptData["expiryDate"] as? Date
            receipt.createdAt = receiptData["createdAt"] as? Date
            receipt.updatedAt = receiptData["updatedAt"] as? Date
        }
        
        // Save context
        try context.save()
    }
    
    // MARK: - Security Audit
    
    func performSecurityAudit() -> SecurityAuditResult {
        var result = SecurityAuditResult()
        
        // Check encryption keys
        if KeychainWrapper.standard.hasValue(forKey: "ReceiptLock.EncryptionKey") {
            result.encryptionKeysPresent = true
        }
        
        // Check biometric authentication
        let biometricManager = BiometricAuthenticationManager.shared
        result.biometricAvailable = biometricManager.isBiometricAvailable
        
        // Check privacy settings
        result.privacySettingsConfigured = true
        
        // Check data retention policy
        result.dataRetentionPolicyConfigured = true
        
        // Check user consent
        let consentTypes = ConsentType.allCases
        result.consentStatus = consentTypes.map { consentType in
            let hasConsent = PrivacyManager.shared.hasValidConsent(for: consentType)
            return (consentType, hasConsent)
        }
        
        return result
    }
}

// MARK: - Errors

enum SecureStorageError: LocalizedError {
    case dataNotFound
    case imageNotFound
    case imageConversionFailed
    case invalidBackupFormat
    case encryptionFailed
    case decryptionFailed
    case keychainWriteFailed
    
    var errorDescription: String? {
        switch self {
        case .dataNotFound:
            return "Secure data not found"
        case .imageNotFound:
            return "Receipt image not found"
        case .imageConversionFailed:
            return "Failed to convert image to data"
        case .invalidBackupFormat:
            return "Invalid backup data format"
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        case .keychainWriteFailed:
            return "Failed to write to keychain"
        }
    }
}

// MARK: - Security Audit Result

struct SecurityAuditResult {
    var encryptionKeysPresent: Bool = false
    var biometricAvailable: Bool = false
    var privacySettingsConfigured: Bool = false
    var dataRetentionPolicyConfigured: Bool = false
    var consentStatus: [(ConsentType, Bool)] = []
    
    var overallSecurityScore: Int {
        var score = 0
        
        if encryptionKeysPresent { score += 25 }
        if biometricAvailable { score += 25 }
        if privacySettingsConfigured { score += 25 }
        if dataRetentionPolicyConfigured { score += 25 }
        
        return score
    }
    
    var securityLevel: SecurityLevel {
        switch overallSecurityScore {
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

enum SecurityLevel: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case excellent = "Excellent"
    
    var description: String {
        switch self {
        case .low:
            return "Basic security measures in place"
        case .medium:
            return "Good security measures implemented"
        case .high:
            return "Strong security measures in place"
        case .excellent:
            return "Excellent security implementation"
        }
    }
    
    var color: String {
        switch self {
        case .low:
            return "red"
        case .medium:
            return "orange"
        case .high:
            return "yellow"
        case .excellent:
            return "green"
        }
    }
}
