//
//  NotificationManager.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import Foundation
import UserNotifications
import CoreData

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func scheduleNotification(for receipt: Receipt) {
        guard let expiryDate = receipt.expiryDate,
              let receiptId = receipt.id else { return }
        
        // Get default reminder days from UserDefaults
        let defaultReminderDays = UserDefaults.standard.integer(forKey: "defaultReminderDays")
        let reminderDays = defaultReminderDays > 0 ? defaultReminderDays : 7
        
        // Calculate reminder date
        guard let reminderDate = Calendar.current.date(byAdding: .day, value: -reminderDays, to: expiryDate) else {
            return
        }
        
        // Only schedule if reminder date is in the future
        guard reminderDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Warranty Expiring Soon"
        content.body = "Your warranty for \(receipt.title ?? "receipt") expires on \(expiryDate.formatted(date: .abbreviated, time: .omitted))"
        content.sound = .default
        content.badge = 1
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "receipt-\(receiptId.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func cancelNotification(for receipt: Receipt) {
        guard let receiptId = receipt.id else { return }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["receipt-\(receiptId.uuidString)"])
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func scheduleNotificationsForAllReceipts(context: NSManagedObjectContext) {
        let request: NSFetchRequest<Receipt> = Receipt.fetchRequest()
        
        do {
            let receipts = try context.fetch(request)
            for receipt in receipts {
                scheduleNotification(for: receipt)
            }
        } catch {
            print("Error fetching receipts for notifications: \(error)")
        }
    }
} 