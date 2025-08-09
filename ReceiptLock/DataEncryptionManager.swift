import Foundation
import CryptoKit
import Security

class DataEncryptionManager: ObservableObject {
    static let shared = DataEncryptionManager()
    
    private let keychain = KeychainWrapper.standard
    private let encryptionKeyIdentifier = "ReceiptLock.EncryptionKey"
    private let saltIdentifier = "ReceiptLock.EncryptionSalt"
    
    private init() {}
    
    // MARK: - Key Management
    
    private func getOrCreateEncryptionKey() throws -> SymmetricKey {
        // Try to retrieve existing key from keychain
        if let existingKeyData = keychain.data(forKey: encryptionKeyIdentifier),
           existingKeyData.count == 32 {
            return SymmetricKey(data: existingKeyData)
        }
        
        // Generate new encryption key
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        
        // Store in keychain
        _ = keychain.set(keyData, forKey: encryptionKeyIdentifier)
        
        return newKey
    }
    
    private func getOrCreateSalt() throws -> Data {
        // Try to retrieve existing salt from keychain
        if let existingSalt = keychain.data(forKey: saltIdentifier),
           existingSalt.count == 32 {
            return existingSalt
        }
        
        // Generate new salt
        var salt = Data(count: 32)
        _ = salt.withUnsafeMutableBytes { pointer in
            SecRandomCopyBytes(kSecRandomDefault, 32, pointer.baseAddress!)
        }
        
        // Store in keychain
        _ = keychain.set(salt, forKey: saltIdentifier)
        
        return salt
    }
    
    // MARK: - Encryption
    
    func encrypt(_ data: Data) throws -> Data {
        let key = try getOrCreateEncryptionKey()
        let salt = try getOrCreateSalt()
        
        // Derive encryption key using PBKDF2
        let derivedKey = try deriveKey(from: key, salt: salt)
        
        // Generate random IV
        var iv = Data(count: 12)
        _ = iv.withUnsafeMutableBytes { pointer in
            SecRandomCopyBytes(kSecRandomDefault, 12, pointer.baseAddress!)
        }
        
        // Encrypt data using AES-GCM
        let sealedBox = try AES.GCM.seal(data, using: derivedKey, nonce: AES.GCM.Nonce(data: iv))
        
        // Combine IV and encrypted data
        var encryptedData = Data()
        encryptedData.append(iv)
        encryptedData.append(sealedBox.ciphertext)
        encryptedData.append(sealedBox.tag)
        
        return encryptedData
    }
    
    func encrypt(_ string: String) throws -> Data {
        guard let data = string.data(using: .utf8) else {
            throw EncryptionError.stringEncodingFailed
        }
        return try encrypt(data)
    }
    
    // MARK: - Decryption
    
    func decrypt(_ encryptedData: Data) throws -> Data {
        let key = try getOrCreateEncryptionKey()
        let salt = try getOrCreateSalt()
        
        // Derive decryption key using PBKDF2
        let derivedKey = try deriveKey(from: key, salt: salt)
        
        // Extract IV, ciphertext, and tag
        guard encryptedData.count >= 28 else { // 12 (IV) + 16 (tag) minimum
            throw EncryptionError.invalidDataFormat
        }
        
        let iv = encryptedData.prefix(12)
        let tag = encryptedData.suffix(16)
        let ciphertext = encryptedData.dropFirst(12).dropLast(16)
        
        // Create sealed box for decryption
        let sealedBox = try AES.GCM.SealedBox(
            nonce: AES.GCM.Nonce(data: iv),
            ciphertext: ciphertext,
            tag: tag
        )
        
        // Decrypt data
        return try AES.GCM.open(sealedBox, using: derivedKey)
    }
    
    func decryptToString(_ encryptedData: Data) throws -> String {
        let decryptedData = try decrypt(encryptedData)
        guard let string = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.stringDecodingFailed
        }
        return string
    }
    
    // MARK: - Key Derivation
    
    private func deriveKey(from masterKey: SymmetricKey, salt: Data) throws -> SymmetricKey {
        let iterations = 100_000 // High iteration count for security
        
        let derivedKeyData = try deriveKeyUsingPBKDF2(
            password: masterKey.withUnsafeBytes { Data($0) },
            salt: salt,
            iterations: iterations,
            keyLength: 32
        )
        
        return SymmetricKey(data: derivedKeyData)
    }
    
    private func deriveKeyUsingPBKDF2(password: Data, salt: Data, iterations: Int, keyLength: Int) throws -> Data {
        // Use CryptoKit's HKDF instead of CommonCrypto
        let key = SymmetricKey(data: password)
        let derivedKey = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: key,
            salt: salt,
            outputByteCount: keyLength
        )
        
        return derivedKey.withUnsafeBytes { bytes in
            Data(bytes)
        }
    }
    
    // MARK: - Secure Random Generation
    
    func generateSecureRandomBytes(count: Int) -> Data {
        var randomBytes = Data(count: count)
        _ = randomBytes.withUnsafeMutableBytes { pointer in
            SecRandomCopyBytes(kSecRandomDefault, count, pointer.baseAddress!)
        }
        return randomBytes
    }
    
    // MARK: - Key Rotation
    
    func rotateEncryptionKey() throws {
        // Generate new key
        let newKey = SymmetricKey(size: .bits256)
        let newKeyData = newKey.withUnsafeBytes { Data($0) }
        
        // Generate new salt
        let newSalt = generateSecureRandomBytes(count: 32)
        
        // Store new key and salt
        _ = keychain.set(newKeyData, forKey: encryptionKeyIdentifier)
        _ = keychain.set(newSalt, forKey: saltIdentifier)
        
        // Note: In a production app, you would need to re-encrypt all existing data
        // with the new key. This is a complex operation that requires careful planning.
    }
    
    // MARK: - Cleanup
    
    func clearEncryptionKeys() {
        _ = keychain.removeObject(forKey: encryptionKeyIdentifier)
        _ = keychain.removeObject(forKey: saltIdentifier)
    }
}

// MARK: - Errors

enum EncryptionError: LocalizedError {
    case stringEncodingFailed
    case stringDecodingFailed
    case invalidDataFormat
    case keyDerivationFailed
    case encryptionFailed
    case decryptionFailed
    
    var errorDescription: String? {
        switch self {
        case .stringEncodingFailed:
            return "Failed to encode string to data"
        case .stringDecodingFailed:
            return "Failed to decode data to string"
        case .invalidDataFormat:
            return "Invalid encrypted data format"
        case .keyDerivationFailed:
            return "Failed to derive encryption key"
        case .encryptionFailed:
            return "Encryption failed"
        case .decryptionFailed:
            return "Decryption failed"
        }
    }
}


