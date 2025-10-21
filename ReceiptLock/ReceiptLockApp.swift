//
//  ReceiptLockApp.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI
import CoreData

@main
struct ReceiptLockApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            AuthenticationWrapperView(requireAuthentication: true, securityLevel: .high, autoLockEnabled: true) {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
            .onAppear {
                NotificationManager.shared.requestPermission()
                // Initialize backup manager
                _ = DataBackupManager.shared
                // Initialize security managers
                _ = BiometricAuthenticationManager.shared
                _ = DataEncryptionManager.shared
                _ = PrivacyManager.shared
                _ = SecureStorageManager.shared
            }
        }
    }
}
