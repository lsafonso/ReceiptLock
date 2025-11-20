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
    
    @ObservedObject private var reminderManager = ReminderManager.shared
    @State private var showingReminderManagement = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppTheme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        // Header
                        headerSection
                            .padding(.top, 24) // H1 top inset 24pt
                        
                        // Active Reminders
                        activeRemindersSection
                            .padding(.top, AppTheme.spacing)
                    }
                }
                .padding(.bottom, AppTheme.tabBarBottomPadding)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showingReminderManagement) {
            ReminderManagementView()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Reminder Overview")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
                
                Spacer()
                
                Image(systemName: "bell.badge.fill")
                    .font(.title)
                    .foregroundColor(AppTheme.primary)
            }
        }
        .padding(.horizontal, 24) // 24pt side insets for card alignment
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
                .background(Color.clear) // Parent paints bg
                .padding(.top, 32) // Block top inset 32 from header
            } else {
                VStack(alignment: .leading, spacing: 16) { // Card→card gap 16pt
                    ForEach(reminderManager.preferences.enabledReminders) { reminder in
                        ReminderDisplayRow(reminder: reminder)
                    }
                }
                .padding(.top, 10)
            }
        }
        .padding(.horizontal, 24) // 24pt side insets for card alignment
    }
}

// MARK: - Supporting Views
struct ReminderDisplayRow: View {
    let reminder: Reminder
    
    var body: some View {
        HStack(spacing: 12) { // Icon to text gap 12pt
            Image(systemName: "bell.fill")
                .foregroundColor(AppTheme.primary)
                .font(.title3)
                .frame(width: 36, height: 36) // Icon 36pt
            
            VStack(alignment: .leading, spacing: 0) {
                Text(reminder.displayText)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(AppTheme.text)
                    .padding(.bottom, 8) // Title→subtitle 8pt
                
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
        .card() // Apply standard card styling
    }
}

#Preview {
    RemindersTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
