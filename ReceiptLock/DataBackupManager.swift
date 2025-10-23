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
import UIKit
import PDFKit

// MARK: - Backup Data Models
struct BackupData: Codable {
    let version: String
    let timestamp: Date
    let receipts: [ReceiptBackup]
    let appliances: [ApplianceBackup]
    let userProfile: UserProfile
    let reminderPreferences: ReminderPreferences
    
    init(
        receipts: [ReceiptBackup],
        appliances: [ApplianceBackup],
        userProfile: UserProfile,
        reminderPreferences: ReminderPreferences
    ) {
        self.version = "1.0"
        self.timestamp = Date()
        self.receipts = receipts
        self.appliances = appliances
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
    let imageDataBase64: String?
    let pdfFileName: String?
    let pdfDataBase64: String?
    let pdfPageCount: Int?
    let pdfProcessed: Bool?
    let createdAt: Date?
    let updatedAt: Date?
    let applianceId: UUID?
    
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
        // Encode image (prefer file on disk; fallback to Core Data binary)
        if let fileName = receipt.fileName,
           let imageURL = DataBackupManager.receiptsDirectory()?.appendingPathComponent(fileName),
           let data = try? Data(contentsOf: imageURL) {
            self.imageDataBase64 = data.base64EncodedString()
        } else if let data = receipt.imageData {
            self.imageDataBase64 = data.base64EncodedString()
        } else {
            self.imageDataBase64 = nil
        }
        // PDF support
        if let pdfURLString = receipt.pdfURL, let url = URL(string: pdfURLString),
           let data = try? Data(contentsOf: url) {
            self.pdfFileName = url.lastPathComponent
            self.pdfDataBase64 = data.base64EncodedString()
        } else {
            self.pdfFileName = nil
            self.pdfDataBase64 = nil
        }
        if receipt.pdfPageCount > 0 { self.pdfPageCount = Int(receipt.pdfPageCount) } else { self.pdfPageCount = nil }
        self.pdfProcessed = receipt.pdfProcessed
        self.createdAt = receipt.createdAt
        self.updatedAt = receipt.updatedAt
        self.applianceId = receipt.appliance?.id
    }
}


// MARK: - Appliance Backup Model
struct ApplianceBackup: Codable {
    let id: UUID
    let name: String?
    let brand: String?
    let model: String?
    let serialNumber: String?
    let purchaseDate: Date?
    let price: Double
    let warrantyMonths: Int16
    let warrantyExpiryDate: Date?
    let warrantySummary: String?
    let notes: String?
    let createdAt: Date?
    let updatedAt: Date?
    
    init(from appliance: Appliance) {
        self.id = appliance.id ?? UUID()
        self.name = appliance.name
        self.brand = appliance.brand
        self.model = appliance.model
        self.serialNumber = appliance.serialNumber
        self.purchaseDate = appliance.purchaseDate
        self.price = appliance.price
        self.warrantyMonths = appliance.warrantyMonths
        self.warrantyExpiryDate = appliance.warrantyExpiryDate
        self.warrantySummary = appliance.warrantySummary
        self.notes = appliance.notes
        self.createdAt = appliance.createdAt
        self.updatedAt = appliance.updatedAt
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
    
    // MARK: - Data Export (ZIP)
    func exportData() async -> URL? {
        await MainActor.run {
            self.isBackingUp = true
            self.backupStatus = .backingUp
            self.syncProgress = 0.0
        }
        
        do {
            // Prepare temp folder
            let tempDir = try makeTempDirectory()
            let jsonURL = tempDir.appendingPathComponent("backup.json")
            
            // Create JSON backup
            let backupData = try await createBackupData()
            let jsonData = try JSONEncoder().encode(backupData)
            try jsonData.write(to: jsonURL)
            
            // Create ZIP file in Documents
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let backupFileName = "ReceiptLock_Backup_\(Date().ISO8601String()).zip"
            let backupURL = documentsPath.appendingPathComponent(backupFileName)
            
            // Remove existing file if present
            try? FileManager.default.removeItem(at: backupURL)
            
            // Create ZIP file using NSFileCoordinator
            try createZipFile(from: tempDir, to: backupURL)
            
            // Cleanup temp dir
            try? FileManager.default.removeItem(at: tempDir)
            
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
    
    // MARK: - Data Import (ZIP or JSON)
    func importData(from url: URL) async -> Bool {
        await MainActor.run {
            self.isRestoring = true
            self.backupStatus = .restoring
            self.syncProgress = 0.0
        }
        
        do {
            if url.pathExtension.lowercased() == "zip" {
                // Extract ZIP file and find JSON
                let tempDir = try makeTempDirectory()
                try extractZipFile(from: url, to: tempDir)
                
                // Look for JSON file in extracted contents
                let jsonURL = tempDir.appendingPathComponent("backup.json")
                guard FileManager.default.fileExists(atPath: jsonURL.path) else {
                    throw NSError(domain: "DataBackupManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No backup.json found in ZIP file"])
                }
                
                let jsonData = try Data(contentsOf: jsonURL)
                let backupData = try JSONDecoder().decode(BackupData.self, from: jsonData)
                try await restoreFromBackup(backupData)
                
                // Cleanup temp dir
                try? FileManager.default.removeItem(at: tempDir)
            } else {
                // Try to handle as JSON
                let jsonData = try Data(contentsOf: url)
                let backupData = try JSONDecoder().decode(BackupData.self, from: jsonData)
                try await restoreFromBackup(backupData)
            }
            
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
        let appliances = try fetchAppliances(context: context)
        let userProfile = UserProfileManager.shared.currentProfile
        var reminderPreferences = ReminderPreferences()
        reminderPreferences.defaultReminders = ReminderManager.shared.preferences.defaultReminders
        reminderPreferences.customReminderMessage = ReminderManager.shared.preferences.customReminderMessage
        reminderPreferences.reminderTime = ReminderManager.shared.preferences.reminderTime
        reminderPreferences.notificationsEnabled = ReminderManager.shared.preferences.notificationsEnabled
        
        return BackupData(
            receipts: receipts,
            appliances: appliances,
            userProfile: userProfile,
            reminderPreferences: reminderPreferences
        )
    }
    
    private func fetchReceipts(context: NSManagedObjectContext) throws -> [ReceiptBackup] {
        let request: NSFetchRequest<Receipt> = Receipt.fetchRequest()
        let receipts = try context.fetch(request)
        return receipts.map { ReceiptBackup(from: $0) }
    }
    
    private func fetchAppliances(context: NSManagedObjectContext) throws -> [ApplianceBackup] {
        let request: NSFetchRequest<Appliance> = Appliance.fetchRequest()
        let appliances = try context.fetch(request)
        return appliances.map { ApplianceBackup(from: $0) }
    }
    

    
    // MARK: - Data Restoration
    private func restoreFromBackup(_ backupData: BackupData) async throws {
        let context = container.viewContext
        
        // Clear existing data
        try clearExistingData(context: context)
        
        // Restore appliances first
        var applianceMap: [UUID: Appliance] = [:]
        for applianceBackup in backupData.appliances {
            let appliance = Appliance(context: context)
            appliance.id = applianceBackup.id
            appliance.name = applianceBackup.name
            appliance.brand = applianceBackup.brand
            appliance.model = applianceBackup.model
            appliance.serialNumber = applianceBackup.serialNumber
            appliance.purchaseDate = applianceBackup.purchaseDate
            appliance.price = applianceBackup.price
            appliance.warrantyMonths = applianceBackup.warrantyMonths
            appliance.warrantyExpiryDate = applianceBackup.warrantyExpiryDate
            appliance.warrantySummary = applianceBackup.warrantySummary
            appliance.notes = applianceBackup.notes
            appliance.createdAt = applianceBackup.createdAt
            appliance.updatedAt = applianceBackup.updatedAt
            applianceMap[applianceBackup.id] = appliance
        }
        
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
            if let applianceId = receiptBackup.applianceId, let appliance = applianceMap[applianceId] {
                receipt.appliance = appliance
            }
            // Restore image data to Core Data and disk
            if let imageBase64 = receiptBackup.imageDataBase64,
               let imageData = Data(base64Encoded: imageBase64) {
                receipt.imageData = imageData
                if let image = UIImage(data: imageData) {
                    let fileName = ImageStorageManager.shared.saveReceiptImage(image, for: receipt)
                    receipt.fileName = fileName
                }
            }
            // Restore PDF data to disk and set URL
            if let pdfBase64 = receiptBackup.pdfDataBase64,
               let pdfData = Data(base64Encoded: pdfBase64) {
                if let pdfURL = try? DataBackupManager.savePDFData(pdfData, preferredFileName: receiptBackup.pdfFileName, for: receipt) {
                    receipt.pdfURL = pdfURL.absoluteString
                    if let doc = PDFDocument(url: pdfURL) {
                        receipt.pdfPageCount = Int16(doc.pageCount)
                        receipt.pdfProcessed = true
                    }
                }
            }
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
        // Delete receipts
        let receiptRequest: NSFetchRequest<NSFetchRequestResult> = Receipt.fetchRequest()
        let receiptDeleteRequest = NSBatchDeleteRequest(fetchRequest: receiptRequest)
        try context.execute(receiptDeleteRequest)
        
        // Delete appliances
        let applianceRequest: NSFetchRequest<NSFetchRequestResult> = Appliance.fetchRequest()
        let applianceDeleteRequest = NSBatchDeleteRequest(fetchRequest: applianceRequest)
        try context.execute(applianceDeleteRequest)
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
            return files.filter { $0.pathExtension == "zip" && $0.lastPathComponent.contains("ReceiptLock_Backup") }
        } catch {
            print("Failed to list backups: \(error)")
            return []
        }
    }
    
    // MARK: - ZIP File Operations
    private func createZipFile(from sourceDirectory: URL, to destinationURL: URL) throws {
        let fileManager = FileManager.default
        
        // Create a temporary ZIP file using NSFileCoordinator
        let coordinator = NSFileCoordinator()
        var error: NSError?
        
        coordinator.coordinate(readingItemAt: sourceDirectory, options: [.forUploading], error: &error) { (coordinatedURL) in
            do {
                // The system automatically creates a ZIP when using .forUploading
                // Copy the created ZIP file to our destination
                try fileManager.copyItem(at: coordinatedURL, to: destinationURL)
            } catch {
                print("Failed to create ZIP file: \(error)")
            }
        }
        
        if let error = error {
            throw error
        }
    }
    
    private func extractZipFile(from zipURL: URL, to destinationDirectory: URL) throws {
        let fileManager = FileManager.default
        
        // Create destination directory if it doesn't exist
        try fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)
        
        // Use NSFileCoordinator to extract the ZIP file
        let coordinator = NSFileCoordinator()
        var error: NSError?
        
        coordinator.coordinate(readingItemAt: zipURL, options: [.forUploading], error: &error) { (coordinatedURL) in
            do {
                // The system automatically extracts ZIP files when using forUploading option
                // Copy all contents from the extracted location to our destination
                let contents = try fileManager.contentsOfDirectory(at: coordinatedURL, includingPropertiesForKeys: nil)
                for item in contents {
                    let destinationItem = destinationDirectory.appendingPathComponent(item.lastPathComponent)
                    try fileManager.copyItem(at: item, to: destinationItem)
                }
            } catch {
                print("Failed to extract ZIP file: \(error)")
            }
        }
        
        if let error = error {
            throw error
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
    
    // MARK: - File Helpers
    static func receiptsDirectory() -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("receipts")
    }
    
    static func savePDFData(_ data: Data, preferredFileName: String?, for receipt: Receipt) throws -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let receiptsDir = documents.appendingPathComponent("receipts")
        try FileManager.default.createDirectory(at: receiptsDir, withIntermediateDirectories: true)
        let name = preferredFileName ?? "\(receipt.id?.uuidString ?? UUID().uuidString).pdf"
        let fileURL = receiptsDir.appendingPathComponent(name)
        try data.write(to: fileURL)
        return fileURL
    }

    private func makeTempDirectory() throws -> URL {
        let tempRoot = FileManager.default.temporaryDirectory
        let dir = tempRoot.appendingPathComponent("ReceiptLock_Backup_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}

// MARK: - Date Extension
extension Date {
    func ISO8601String() -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}
