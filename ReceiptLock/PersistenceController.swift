//
//  PersistenceController.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import CoreData
import CloudKit
import Foundation

class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        let enableCloud = UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")
        let cloudContainer = NSPersistentCloudKitContainer(name: "ReceiptLock")
        container = cloudContainer
        
        if inMemory {
            cloudContainer.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Enable CloudKit sync and encryption
            cloudContainer.persistentStoreDescriptions.forEach { storeDescription in
                storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
                
                // Enable encryption for Core Data
                storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreFileProtectionKey)
                
                // Enable automatic migration options (safety nets)
                storeDescription.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
                storeDescription.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
                
                // Configure CloudKit container options based on user setting
                if enableCloud {
                    let bundleId = Bundle.main.bundleIdentifier ?? "com.example.ReceiptLock"
                    let containerId = "iCloud.\(bundleId)"
                    let options = NSPersistentCloudKitContainerOptions(containerIdentifier: containerId)
                    storeDescription.cloudKitContainerOptions = options
                } else {
                    storeDescription.cloudKitContainerOptions = nil
                }
            }
        }
        
        let shouldRunMigration = !inMemory
        
        cloudContainer.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            
            // Run migration if needed
            if shouldRunMigration {
                PersistenceController.migrateToReceiptItemModel(context: cloudContainer.viewContext)
            }
        }
        
        cloudContainer.viewContext.automaticallyMergesChangesFromParent = true
        cloudContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // MARK: - Migration
    
    private static func migrateToReceiptItemModel(context: NSManagedObjectContext) {
        // Check if migration has already been run
        let migrationKey = "ReceiptItemMigrationCompleted"
        if UserDefaults.standard.bool(forKey: migrationKey) {
            return
        }
        
        print("[Migration] Starting ReceiptItem migration...")
        
        context.performAndWait {
            // Try to find receipts with old appliance relationship using KVC (for backward compatibility)
            let receiptFetch = NSFetchRequest<NSManagedObject>(entityName: "Receipt")
            
            do {
                let receipts = try context.fetch(receiptFetch)
                print("[Migration] Found \(receipts.count) receipts to check")
                
                var migratedCount = 0
                for receipt in receipts {
                    // Check if old appliance relationship exists (using KVC)
                    if let appliance = receipt.value(forKey: "appliance") as? Appliance {
                        // Create ReceiptItem
                        let receiptItem = ReceiptItem(context: context)
                        receiptItem.id = UUID()
                        receiptItem.receipt = receipt as? Receipt
                        receiptItem.appliance = appliance
                        
                        // Extract originalLineText from appliance notes if present
                        if let notes = appliance.notes, notes.contains("From receipt:") {
                            // Extract the line text after "From receipt: "
                            if let range = notes.range(of: "From receipt: ") {
                                let lineText = String(notes[range.upperBound...])
                                    .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                                // Remove receipt ID if present
                                if let receiptIdRange = lineText.range(of: "\nReceipt ID:") {
                                    receiptItem.originalLineText = String(lineText[..<receiptIdRange.lowerBound])
                                } else {
                                    receiptItem.originalLineText = lineText
                                }
                            }
                        } else {
                            // Fallback: use appliance name
                            receiptItem.originalLineText = appliance.name ?? "Unknown item"
                        }
                        
                        // Set lineAmount from appliance price if available
                        if appliance.price > 0 {
                            receiptItem.lineAmount = NSDecimalNumber(value: appliance.price)
                        }
                        
                        receiptItem.quantity = 1
                        
                        // Clean up notes: remove "From receipt:" and receipt ID lines
                        if var notes = appliance.notes {
                            // Remove "From receipt:" line
                            notes = notes.replacingOccurrences(of: #"From receipt:.*"#, with: "", options: .regularExpression)
                            // Remove receipt ID line
                            notes = notes.replacingOccurrences(of: #"\nReceipt ID:.*"#, with: "", options: .regularExpression)
                            notes = notes.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                            appliance.notes = notes.isEmpty ? nil : notes
                        }
                        
                        // Remove old appliance relationship (set to nil)
                        receipt.setValue(nil, forKey: "appliance")
                        migratedCount += 1
                    }
                }
                
                if migratedCount > 0 {
                    // Save migration
                    try context.save()
                    print("[Migration] created \(migratedCount) ReceiptItems")
                    print("[Migration] Migrated \(migratedCount) receipts successfully")
                }
                
                // Verify receipt ID removal from notes
                let applianceFetch = NSFetchRequest<NSManagedObject>(entityName: "Appliance")
                let appliances = try context.fetch(applianceFetch)
                var foundReceiptIdInNotes = 0
                for appliance in appliances {
                    if let notes = appliance.value(forKey: "notes") as? String,
                       notes.contains("Receipt ID:") {
                        foundReceiptIdInNotes += 1
                        print("[Migration] WARNING: Found receipt ID in notes for appliance: \(appliance.value(forKey: "name") ?? "unknown")")
                    }
                }
                if foundReceiptIdInNotes > 0 {
                    print("[Migration] WARNING: Found \(foundReceiptIdInNotes) appliances with receipt ID still in notes")
                } else {
                    print("[Migration] Verified: All receipt ID artifacts removed from notes")
                }
                
                UserDefaults.standard.set(true, forKey: migrationKey)
                print("[Migration] Migration completed successfully")
            } catch {
                print("❌ [Migration] Error during migration: \(error)")
                // Don't fatal error - allow app to continue
            }
        }
    }
    
    // MARK: - Preview Helper
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample data for previews
        let sampleReceipt = Receipt(context: viewContext)
        sampleReceipt.id = UUID()
        sampleReceipt.title = "iPhone 15 Pro"
        sampleReceipt.store = "Apple Store"
        sampleReceipt.purchaseDate = Date()
        sampleReceipt.price = 999.99
        sampleReceipt.warrantyMonths = 12
        sampleReceipt.expiryDate = Calendar.current.date(byAdding: .month, value: 12, to: Date())
        sampleReceipt.createdAt = Date()
        sampleReceipt.updatedAt = Date()
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        return result
    }()
} 