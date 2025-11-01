//
//  ReminderStatusView.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI

// MARK: - Reminder Status View
struct ReminderStatusView: View {
    let receipt: Receipt
    @ObservedObject private var reminderManager = ReminderManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(AppTheme.primary)
                    .font(.caption)
                
                Text("Reminders")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.text)
                
                Spacer()
                
                if reminderManager.isUpdatingNotifications {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            
            if let expiryDate = receipt.expiryDate {
                let enabledReminders = reminderManager.preferences.enabledReminders
                let activeReminders = enabledReminders.filter { reminder in
                    if let reminderDate = Calendar.current.date(byAdding: .day, value: -reminder.daysBeforeExpiry, to: expiryDate) {
                        return reminderDate > Date()
                    }
                    return false
                }
                
                if activeReminders.isEmpty {
                    Text("No active reminders")
                        .font(.caption2)
                        .foregroundColor(AppTheme.secondaryText)
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(activeReminders.prefix(3)) { reminder in
                            HStack {
                                Text("•")
                                    .foregroundColor(AppTheme.primary)
                                    .font(.caption2)
                                
                                Text(reminder.displayText)
                                    .font(.caption2)
                                    .foregroundColor(AppTheme.secondaryText)
                                
                                Spacer()
                            }
                        }
                        
                        if activeReminders.count > 3 {
                            Text("+\(activeReminders.count - 3) more")
                                .font(.caption2)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                }
            } else {
                Text("No warranty period set")
                    .font(.caption2)
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
        .padding(AppTheme.smallSpacing)
        .background(AppTheme.cardBackground.opacity(0.5))
        .cornerRadius(AppTheme.cornerRadius)
    }
}

// MARK: - Reminder Quick Actions
struct ReminderQuickActions: View {
    let receipt: Receipt
    @ObservedObject private var reminderManager = ReminderManager.shared
    @State private var showingReminderManagement = false
    
    var body: some View {
        VStack(spacing: AppTheme.smallSpacing) {
            Button(action: {
                showingReminderManagement = true
            }) {
                HStack {
                    Image(systemName: "bell.badge")
                        .font(.caption)
                    
                    Text("Manage Reminders")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(AppTheme.primary)
                .padding(.horizontal, AppTheme.smallSpacing)
                .padding(.vertical, 6)
                .background(AppTheme.primary.opacity(0.1))
                .cornerRadius(AppTheme.cornerRadius)
            }
            
            if reminderManager.preferences.notificationsEnabled {
                Button(action: {
                    reminderManager.toggleNotifications(false)
                }) {
                    HStack {
                        Image(systemName: "bell.slash")
                            .font(.caption)
                        
                        Text("Disable Notifications")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(AppTheme.error)
                    .padding(.horizontal, AppTheme.smallSpacing)
                    .padding(.vertical, 6)
                    .background(AppTheme.error.opacity(0.1))
                    .cornerRadius(AppTheme.cornerRadius)
                }
            } else {
                Button(action: {
                    reminderManager.toggleNotifications(true)
                }) {
                    HStack {
                        Image(systemName: "bell")
                            .font(.caption)
                        
                        Text("Enable Notifications")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(AppTheme.primary)
                    .padding(.horizontal, AppTheme.smallSpacing)
                    .padding(.vertical, 6)
                    .background(AppTheme.primary.opacity(0.1))
                    .cornerRadius(AppTheme.cornerRadius)
                }
            }
        }
        .sheet(isPresented: $showingReminderManagement) {
            ReminderManagementView()
        }
    }
}

// MARK: - Reminder Count Badge
struct ReminderCountBadge: View {
    let receipt: Receipt
    @ObservedObject private var reminderManager = ReminderManager.shared
    
    var body: some View {
        if let expiryDate = receipt.expiryDate {
            let enabledReminders = reminderManager.preferences.enabledReminders
            let activeReminders = enabledReminders.filter { reminder in
                if let reminderDate = Calendar.current.date(byAdding: .day, value: -reminder.daysBeforeExpiry, to: expiryDate) {
                    return reminderDate > Date()
                }
                return false
            }
            
            if !activeReminders.isEmpty {
                Text("\(activeReminders.count)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.onPrimary)
                    .frame(width: 16, height: 16)
                    .background(AppTheme.primary)
                    .clipShape(Circle())
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let receipt = Receipt(context: context)
    receipt.id = UUID()
    receipt.title = "iPhone 15 Pro"
    receipt.store = "Apple Store"
    receipt.price = 999.99
    receipt.purchaseDate = Date()
    receipt.warrantyMonths = 12
    receipt.expiryDate = Calendar.current.date(byAdding: .month, value: 12, to: Date())
    
    return VStack(spacing: AppTheme.spacing) {
        ReminderStatusView(receipt: receipt)
        ReminderQuickActions(receipt: receipt)
        HStack {
            Text("Reminders:")
            ReminderCountBadge(receipt: receipt)
        }
    }
    .padding()
    .environment(\.managedObjectContext, context)
}
