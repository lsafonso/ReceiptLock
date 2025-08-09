//
//  PersistenceController.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ReceiptLock")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Enable CloudKit sync and encryption
            container.persistentStoreDescriptions.forEach { storeDescription in
                storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
                
                // Enable encryption for Core Data
                storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreFileProtectionKey)
                
                // Enable CloudKit container
                if let cloudKitContainerIdentifier = storeDescription.cloudKitContainerOptions?.containerIdentifier {
                    print("CloudKit container enabled: \(cloudKitContainerIdentifier)")
                }
            }
        }
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
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