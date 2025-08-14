//
//  RemindersTabView.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI
import CoreData

struct RemindersTabView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Receipt.expiryDate, ascending: true)],
        animation: .default)
    private var receipts: FetchedResults<Receipt>
    
    @ObservedObject private var reminderManager = ReminderManager.shared
    @State private var showingReminderManagement = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppTheme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: AppTheme.largeSpacing) {
                        // Header
                        headerSection
                        
                        // Active Reminders
                        activeRemindersSection
                        
                        // Upcoming Reminders
                        upcomingRemindersSection
                        
                        // Reminder Settings
                        reminderSettingsSection
                    }
                    .padding(AppTheme.spacing)
                }
            }
            .navigationTitle("Reminders")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Manage") {
                        showingReminderManagement = true
                    }
                    .foregroundColor(AppTheme.primary)
                }
            }
        }
        .sheet(isPresented: $showingReminderManagement) {
            ReminderManagementView()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reminder Overview")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                    
                    Text("Stay on top of your warranties")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(AppTheme.text)
                }
                
                Spacer()
                
                Image(systemName: "bell.badge.fill")
                    .font(.title)
                    .foregroundColor(AppTheme.primary)
            }
        }
        .padding(.horizontal, AppTheme.spacing)
    }
    
    // MARK: - Active Reminders Section
    private var activeRemindersSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            Text("Active Reminders")
                .font(.headline.weight(.semibold))
                .foregroundColor(AppTheme.text)
            
            if reminderManager.preferences.enabledReminders.isEmpty {
                EmptyStateView(
                    title: "No Active Reminders",
                    message: "Configure reminder settings to get notified about warranty expirations.",
                    systemImage: "bell.slash"
                )
            } else {
                VStack(spacing: AppTheme.spacing) {
                    ForEach(reminderManager.preferences.enabledReminders) { reminder in
                        ReminderDisplayRow(reminder: reminder)
                    }
                }
            }
        }
    }
    
    // MARK: - Upcoming Reminders Section
    private var upcomingRemindersSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            Text("Upcoming Reminders")
                .font(.headline.weight(.semibold))
                .foregroundColor(AppTheme.text)
            
            let upcomingReminders = getUpcomingReminders()
            
            if upcomingReminders.isEmpty {
                EmptyStateView(
                    title: "No Upcoming Reminders",
                    message: "All your warranties are up to date.",
                    systemImage: "checkmark.circle"
                )
            } else {
                VStack(spacing: AppTheme.spacing) {
                    ForEach(upcomingReminders.prefix(5)) { reminder in
                        UpcomingReminderRowView(reminder: reminder)
                    }
                }
            }
        }
    }
    
    // MARK: - Reminder Settings Section
    private var reminderSettingsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            Text("Quick Actions")
                .font(.headline.weight(.semibold))
                .foregroundColor(AppTheme.text)
            
            VStack(spacing: AppTheme.smallSpacing) {
                Button(action: { showingReminderManagement = true }) {
                    HStack {
                        Image(systemName: "bell.badge")
                            .foregroundColor(AppTheme.primary)
                        
                        Text("Manage Reminder Settings")
                            .foregroundColor(AppTheme.text)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .padding(AppTheme.spacing)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(AppTheme.cornerRadius)
                }
                
                NavigationLink(destination: NotificationPreferencesView()) {
                    HStack {
                        Image(systemName: "gearshape")
                            .foregroundColor(AppTheme.primary)
                        
                        Text("Notification Preferences")
                            .foregroundColor(AppTheme.text)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .padding(AppTheme.spacing)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(AppTheme.cornerRadius)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func getUpcomingReminders() -> [UpcomingReminder] {
        var upcoming: [UpcomingReminder] = []
        
        for receipt in receipts {
            if let expiryDate = receipt.expiryDate {
                for reminder in reminderManager.preferences.enabledReminders {
                    if let reminderDate = Calendar.current.date(byAdding: .day, value: -reminder.daysBeforeExpiry, to: expiryDate) {
                        if reminderDate > Date() {
                            upcoming.append(UpcomingReminder(
                                receipt: receipt,
                                reminder: reminder,
                                reminderDate: reminderDate
                            ))
                        }
                    }
                }
            }
        }
        
        return upcoming.sorted { $0.reminderDate < $1.reminderDate }
    }
}

// MARK: - Supporting Views
struct ReminderDisplayRow: View {
    let reminder: Reminder
    
    var body: some View {
        HStack {
            Image(systemName: "bell.fill")
                .foregroundColor(AppTheme.primary)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.displayText)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(AppTheme.text)
                
                Text("\(reminder.daysBeforeExpiry) days before expiry")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            Spacer()
            
            if reminder.isEnabled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppTheme.success)
                    .font(.title3)
            } else {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(AppTheme.error)
                    .font(.title3)
            }
        }
        .padding(AppTheme.spacing)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadius)
    }
}

struct UpcomingReminderRowView: View {
    let reminder: UpcomingReminder
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.receipt.title ?? "Unknown Receipt")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(AppTheme.text)
                
                Text("Reminder: \(reminder.reminder.displayText)")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            Spacer()
            
            Text(reminder.reminderDate, style: .date)
                .font(.caption)
                .foregroundColor(AppTheme.primary)
        }
        .padding(AppTheme.spacing)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadius)
    }
}

struct UpcomingReminder: Identifiable {
    let id = UUID()
    let receipt: Receipt
    let reminder: Reminder
    let reminderDate: Date
}

#Preview {
    RemindersTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
