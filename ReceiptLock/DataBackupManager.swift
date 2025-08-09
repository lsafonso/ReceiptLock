//
//  DataBackupManager.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import Foundation
import CoreData
import CloudKit
import SwiftUI

// MARK: - Backup Data Models
struct BackupData: Codable {
    let version: String
    let timestamp: Date
    let receipts: [ReceiptBackup]
    let userProfile: UserProfile
    let reminderPreferences: ReminderPreferences
    
    init(
        receipts: [ReceiptBackup],
        userProfile: UserProfile,
        reminderPreferences: ReminderPreferences
    ) {
        self.version = "1.0"
        self.timestamp = Date()
        self.receipts = receipts
        self.userProfile = userProfile
        self.reminderPreferences = reminderPreferences
    }
}

struct ReceiptBackup: Codable {
    let id: UUID
    let title: String
    let store: String?
    let purchaseDate: Date?
    let price: Double
    let warrantyMonths: Int16
    let expiryDate: Date?
    let warrantySummary: String?
    let fileName: String?
    let createdAt: Date?
    let updatedAt: Date?
    
    init(from receipt: Receipt) {
        self.id = receipt.id ?? UUID()
        self.title = receipt.title ?? ""
        self.store = receipt.store
        self.purchaseDate = receipt.purchaseDate
        self.price = receipt.price
        self.warrantyMonths = receipt.warrantyMonths
        self.expiryDate = receipt.expiryDate
        self.warrantySummary = receipt.warrantySummary
        self.fileName = receipt.fileName
        self.createdAt = receipt.createdAt
        self.updatedAt = receipt.updatedAt
    }
}





// MARK: - Data Backup Manager
class DataBackupManager: ObservableObject {
    static let shared = DataBackupManager()
    
    @Published var isBackingUp = false
    @Published var isRestoring = false
    @Published var lastBackupDate: Date?
    @Published var backupStatus: BackupStatus = .idle
    @Published var syncProgress: Double = 0.0
    
    private let container: NSPersistentContainer
    private let userDefaults = UserDefaults.standard
    private let backupKey = "lastBackupDate"
    private let iCloudKey = "iCloudSyncEnabled"
    
    enum BackupStatus {
        case idle
        case backingUp
        case restoring
        case completed
        case failed(String)
    }
    
    private init() {
        self.container = PersistenceController.shared.container
        self.lastBackupDate = userDefaults.object(forKey: backupKey) as? Date
        setupCloudKitSync()
    }
    
    // MARK: - iCloud Sync Setup
    private func setupCloudKitSync() {
        guard isCloudKitAvailable() else { return }
        
        // Enable CloudKit sync for Core Data
        container.persistentStoreDescriptions.forEach { storeDescription in
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }
        
        // Listen for remote changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRemoteChange),
            name: .NSPersistentStoreRemoteChange,
            object: nil
        )
    }
    
    private func isCloudKitAvailable() -> Bool {
        return FileManager.default.ubiquityIdentityToken != nil
    }
    
    @objc private func handleRemoteChange(_ notification: Notification) {
        DispatchQueue.main.async {
            self.syncProgress = 1.0
            self.backupStatus = .completed
            self.lastBackupDate = Date()
            self.saveBackupDate()
        }
    }
    
    // MARK: - Data Export
    func exportData() async -> URL? {
        await MainActor.run {
            self.isBackingUp = true
            self.backupStatus = .backingUp
            self.syncProgress = 0.0
        }
        
        do {
            let backupData = try await createBackupData()
            let jsonData = try JSONEncoder().encode(backupData)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let backupFileName = "ReceiptLock_Backup_\(Date().ISO8601String()).json"
            let backupURL = documentsPath.appendingPathComponent(backupFileName)
            
            try jsonData.write(to: backupURL)
            
            await MainActor.run {
                self.isBackingUp = false
                self.backupStatus = .completed
                self.syncProgress = 1.0
                self.lastBackupDate = Date()
                self.saveBackupDate()
            }
            
            return backupURL
        } catch {
            await MainActor.run {
                self.isBackingUp = false
                self.backupStatus = .failed(error.localizedDescription)
            }
            print("Export failed: \(error)")
            return nil
        }
    }
    
    // MARK: - Data Import
    func importData(from url: URL) async -> Bool {
        await MainActor.run {
            self.isRestoring = true
            self.backupStatus = .restoring
            self.syncProgress = 0.0
        }
        
        do {
            let jsonData = try Data(contentsOf: url)
            let backupData = try JSONDecoder().decode(BackupData.self, from: jsonData)
            
            try await restoreFromBackup(backupData)
            
            await MainActor.run {
                self.isRestoring = false
                self.backupStatus = .completed
                self.syncProgress = 1.0
            }
            
            return true
        } catch {
            await MainActor.run {
                self.isRestoring = false
                self.backupStatus = .failed(error.localizedDescription)
            }
            print("Import failed: \(error)")
            return false
        }
    }
    
    // MARK: - Backup Creation
    private func createBackupData() async throws -> BackupData {
        let context = container.viewContext
        
        let receipts = try fetchReceipts(context: context)
        let userProfile = UserProfileManager.shared.currentProfile
        var reminderPreferences = ReminderPreferences()
        reminderPreferences.defaultReminders = ReminderManager.shared.preferences.defaultReminders
        reminderPreferences.customReminderMessage = ReminderManager.shared.preferences.customReminderMessage
        reminderPreferences.reminderTime = ReminderManager.shared.preferences.reminderTime
        reminderPreferences.notificationsEnabled = ReminderManager.shared.preferences.notificationsEnabled
        
        return BackupData(
            receipts: receipts,
            userProfile: userProfile,
            reminderPreferences: reminderPreferences
        )
    }
    
    private func fetchReceipts(context: NSManagedObjectContext) throws -> [ReceiptBackup] {
        let request: NSFetchRequest<Receipt> = Receipt.fetchRequest()
        let receipts = try context.fetch(request)
        return receipts.map { ReceiptBackup(from: $0) }
    }
    

    
    // MARK: - Data Restoration
    private func restoreFromBackup(_ backupData: BackupData) async throws {
        let context = container.viewContext
        
        // Clear existing data
        try clearExistingData(context: context)
        
        // Restore receipts
        for receiptBackup in backupData.receipts {
            let receipt = Receipt(context: context)
            receipt.id = receiptBackup.id
            receipt.title = receiptBackup.title
            receipt.store = receiptBackup.store
            receipt.purchaseDate = receiptBackup.purchaseDate
            receipt.price = receiptBackup.price
            receipt.warrantyMonths = receiptBackup.warrantyMonths
            receipt.expiryDate = receiptBackup.expiryDate
            receipt.warrantySummary = receiptBackup.warrantySummary
            receipt.fileName = receiptBackup.fileName
            receipt.createdAt = receiptBackup.createdAt
            receipt.updatedAt = receiptBackup.updatedAt
        }
        
        // Save context
        try context.save()
        
        // Restore user profile and preferences
        UserProfileManager.shared.updateProfile(backupData.userProfile)
        
        // Restore reminder preferences
        ReminderManager.shared.preferences.notificationsEnabled = backupData.reminderPreferences.notificationsEnabled
        ReminderManager.shared.preferences.defaultReminders = backupData.reminderPreferences.defaultReminders
        ReminderManager.shared.preferences.customReminderMessage = backupData.reminderPreferences.customReminderMessage
        ReminderManager.shared.preferences.reminderTime = backupData.reminderPreferences.reminderTime
    }
    
    private func clearExistingData(context: NSManagedObjectContext) throws {
        let receiptRequest: NSFetchRequest<NSFetchRequestResult> = Receipt.fetchRequest()
        let receiptDeleteRequest = NSBatchDeleteRequest(fetchRequest: receiptRequest)
        
        try context.execute(receiptDeleteRequest)
    }
    
    // MARK: - CloudKit Sync
    func syncWithCloud() async {
        guard isCloudKitAvailable() else {
            await MainActor.run {
                self.backupStatus = .failed("iCloud not available")
            }
            return
        }
        
        await MainActor.run {
            self.isBackingUp = true
            self.backupStatus = .backingUp
            self.syncProgress = 0.0
        }
        
        do {
            // Trigger CloudKit sync
            try container.viewContext.save()
            
            await MainActor.run {
                self.syncProgress = 0.5
            }
            
            // Wait a bit for sync to complete
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            await MainActor.run {
                self.isBackingUp = false
                self.backupStatus = .completed
                self.syncProgress = 1.0
                self.lastBackupDate = Date()
                self.saveBackupDate()
            }
        } catch {
            await MainActor.run {
                self.isBackingUp = false
                self.backupStatus = .failed(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Backup Management
    func deleteBackup(at url: URL) -> Bool {
        do {
            try FileManager.default.removeItem(at: url)
            return true
        } catch {
            print("Failed to delete backup: \(error)")
            return false
        }
    }
    
    func listBackups() -> [URL] {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: nil)
            return files.filter { $0.pathExtension == "json" && $0.lastPathComponent.contains("ReceiptLock_Backup") }
        } catch {
            print("Failed to list backups: \(error)")
            return []
        }
    }
    
    // MARK: - Utility Methods
    private func saveBackupDate() {
        userDefaults.set(lastBackupDate, forKey: backupKey)
    }
    
    func isCloudKitEnabled() -> Bool {
        return userDefaults.bool(forKey: iCloudKey)
    }
    
    func setCloudKitEnabled(_ enabled: Bool) {
        userDefaults.set(enabled, forKey: iCloudKey)
    }
}

// MARK: - Date Extension
extension Date {
    func ISO8601String() -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}
