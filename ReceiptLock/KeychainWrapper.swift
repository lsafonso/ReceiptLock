import Foundation
import Security

class KeychainWrapper {
    static let standard = KeychainWrapper()
    
    private init() {}
    
    // MARK: - Generic Data Storage
    
    func set(_ value: Data, forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: value,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Remove any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func data(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        
        return data
    }
    
    func string(forKey key: String) -> String? {
        guard let data = data(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func set(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        return set(data, forKey: key)
    }
    
    // MARK: - Boolean Storage
    
    func bool(forKey key: String) -> Bool? {
        guard let data = data(forKey: key) else { return nil }
        return data.withUnsafeBytes { $0.load(as: Bool.self) }
    }
    
    func set(_ value: Bool, forKey key: String) -> Bool {
        var boolValue = value
        let data = Data(bytes: &boolValue, count: MemoryLayout<Bool>.size)
        return set(data, forKey: key)
    }
    
    // MARK: - Integer Storage
    
    func integer(forKey key: String) -> Int? {
        guard let data = data(forKey: key) else { return nil }
        return data.withUnsafeBytes { $0.load(as: Int.self) }
    }
    
    func set(_ value: Int, forKey key: String) -> Bool {
        var intValue = value
        let data = Data(bytes: &intValue, count: MemoryLayout<Int>.size)
        return set(data, forKey: key)
    }
    
    // MARK: - Double Storage
    
    func double(forKey key: String) -> Double? {
        guard let data = data(forKey: key) else { return nil }
        return data.withUnsafeBytes { $0.load(as: Double.self) }
    }
    
    func set(_ value: Double, forKey key: String) -> Bool {
        var doubleValue = value
        let data = Data(bytes: &doubleValue, count: MemoryLayout<Double>.size)
        return set(data, forKey: key)
    }
    
    // MARK: - Date Storage
    
    func date(forKey key: String) -> Date? {
        guard let data = data(forKey: key) else { return nil }
        let timeInterval = data.withUnsafeBytes { $0.load(as: TimeInterval.self) }
        return Date(timeIntervalSinceReferenceDate: timeInterval)
    }
    
    func set(_ value: Date, forKey key: String) -> Bool {
        let timeInterval = value.timeIntervalSinceReferenceDate
        var timeIntervalValue = timeInterval
        let data = Data(bytes: &timeIntervalValue, count: MemoryLayout<TimeInterval>.size)
        return set(data, forKey: key)
    }
    
    // MARK: - Removal
    
    func removeObject(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Existence Check
    
    func hasValue(forKey key: String) -> Bool {
        return data(forKey: key) != nil
    }
    
    // MARK: - Clear All
    
    func clearAll() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - All Keys
    
    func allKeys() -> [String] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let items = result as? [[String: Any]] else {
            return []
        }
        
        return items.compactMap { $0[kSecAttrAccount as String] as? String }
    }
}
