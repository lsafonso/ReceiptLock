//
//  ReminderSystem.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import Foundation
import SwiftUI
import UserNotifications
import CoreData

// MARK: - Reminder Model
struct Reminder: Identifiable, Codable {
    let id: UUID
    var daysBeforeExpiry: Int
    var message: String
    var isEnabled: Bool
    var customTime: Date?
    
    init(daysBeforeExpiry: Int, message: String = "", isEnabled: Bool = true, customTime: Date? = nil) {
        self.id = UUID()
        self.daysBeforeExpiry = daysBeforeExpiry
        self.message = message
        self.isEnabled = isEnabled
        self.customTime = customTime
    }
    
    var displayText: String {
        if daysBeforeExpiry == 0 {
            return "On expiry date"
        } else if daysBeforeExpiry == 1 {
            return "1 day before"
        } else {
            return "\(daysBeforeExpiry) days before"
        }
    }
    
    var notificationIdentifier: String {
        return "reminder-\(id.uuidString)"
    }
}

// MARK: - Reminder Preferences
struct ReminderPreferences: Codable {
    var defaultReminders: [Reminder]
    var customReminderMessage: String
    var reminderTime: Date
    var notificationsEnabled: Bool
    
    init() {
        self.defaultReminders = [
            Reminder(daysBeforeExpiry: 7, message: "Your warranty expires in 7 days"),
            Reminder(daysBeforeExpiry: 14, message: "Your warranty expires in 14 days"),
            Reminder(daysBeforeExpiry: 30, message: "Your warranty expires in 30 days")
        ]
        self.customReminderMessage = ""
        self.reminderTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
        self.notificationsEnabled = true
    }
    
    var enabledReminders: [Reminder] {
        return defaultReminders.filter { $0.isEnabled }
    }
}

// MARK: - Reminder Manager
class ReminderManager: ObservableObject {
    static let shared = ReminderManager()
    
    @Published var preferences: ReminderPreferences
    @Published var isUpdatingNotifications = false
    
    private let userDefaults = UserDefaults.standard
    private let preferencesKey = "reminderPreferences"
    
    private init() {
        if let data = userDefaults.data(forKey: preferencesKey),
           let prefs = try? JSONDecoder().decode(ReminderPreferences.self, from: data) {
            self.preferences = prefs
        } else {
            self.preferences = ReminderPreferences()
        }
    }
    
    // MARK: - Preferences Management
    
    func updatePreferences(_ newPreferences: ReminderPreferences) {
        preferences = newPreferences
        savePreferences()
        
        // Reschedule all notifications with new preferences
        Task {
            await rescheduleAllNotifications()
        }
    }
    
    func toggleReminder(_ reminder: Reminder) {
        if let index = preferences.defaultReminders.firstIndex(where: { $0.id == reminder.id }) {
            preferences.defaultReminders[index].isEnabled.toggle()
            savePreferences()
            
            // Reschedule notifications for this specific reminder
            Task {
                await rescheduleAllNotifications()
            }
        }
    }
    
    func updateReminderMessage(_ reminder: Reminder, message: String) {
        if let index = preferences.defaultReminders.firstIndex(where: { $0.id == reminder.id }) {
            preferences.defaultReminders[index].message = message
            savePreferences()
            
            // Reschedule notifications for this specific reminder
            Task {
                await rescheduleAllNotifications()
            }
        }
    }
    
    func updateCustomMessage(_ message: String) {
        preferences.customReminderMessage = message
        savePreferences()
        
        // Reschedule all notifications with new custom message
        Task {
            await rescheduleAllNotifications()
        }
    }
    
    func updateReminderTime(_ time: Date) {
        preferences.reminderTime = time
        savePreferences()
        
        // Reschedule all notifications with new time
        Task {
            await rescheduleAllNotifications()
        }
    }
    
    func toggleNotifications(_ enabled: Bool) {
        preferences.notificationsEnabled = enabled
        savePreferences()
        
        if enabled {
            Task {
                await rescheduleAllNotifications()
            }
        } else {
            cancelAllNotifications()
        }
    }
    
    // MARK: - Notification Management
    
    func scheduleNotifications(for receipt: Receipt) async {
        guard preferences.notificationsEnabled,
              let _ = receipt.expiryDate,
              let _ = receipt.id else { return }
        
        for reminder in preferences.enabledReminders {
            await scheduleNotification(for: receipt, reminder: reminder)
        }
    }
    
    func scheduleNotifications(for appliance: Appliance) async {
        guard preferences.notificationsEnabled,
              let _ = appliance.warrantyExpiryDate,
              let _ = appliance.id else { return }
        
        for reminder in preferences.enabledReminders {
            await scheduleNotification(for: appliance, reminder: reminder)
        }
    }
    
    private func scheduleNotification(for receipt: Receipt, reminder: Reminder) async {
        guard let expiryDate = receipt.expiryDate,
              let receiptId = receipt.id else { return }
        
        // Calculate reminder date
        guard let reminderDate = Calendar.current.date(byAdding: .day, value: -reminder.daysBeforeExpiry, to: expiryDate) else {
            return
        }
        
        // Only schedule if reminder date is in the future
        guard reminderDate > Date() else { return }
        
        // Use custom time if available, otherwise use default reminder time
        let reminderTime = reminder.customTime ?? preferences.reminderTime
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
        
        // Combine reminder date with reminder time
        var finalReminderDate = calendar.date(bySettingHour: timeComponents.hour ?? 9, minute: timeComponents.minute ?? 0, second: 0, of: reminderDate) ?? reminderDate
        
        // If the combined time is in the past, move to next day
        if finalReminderDate <= Date() {
            finalReminderDate = calendar.date(byAdding: .day, value: 1, to: finalReminderDate) ?? finalReminderDate
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Warranty Reminder"
        
        // Use custom message if available, otherwise use default
        let message = reminder.message.isEmpty ? 
            "Your warranty for \(receipt.title ?? "appliance") expires on \(expiryDate.formatted(date: .abbreviated, time: .omitted))" :
            reminder.message.replacingOccurrences(of: "{appliance}", with: receipt.title ?? "appliance")
            .replacingOccurrences(of: "{expiryDate}", with: expiryDate.formatted(date: .abbreviated, time: .omitted))
            .replacingOccurrences(of: "{daysLeft}", with: "\(reminder.daysBeforeExpiry)")
        
        content.body = message
        content.sound = .default
        content.badge = 1
        
        // Add user info for deep linking
        content.userInfo = [
            "receiptId": receiptId.uuidString,
            "reminderType": "warranty",
            "daysBeforeExpiry": reminder.daysBeforeExpiry
        ]
        
        let triggerDate = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: finalReminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "\(receiptId.uuidString)-\(reminder.daysBeforeExpiry)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Scheduled notification for \(receipt.title ?? "appliance") \(reminder.displayText)")
        } catch {
            print("Error scheduling notification: \(error)")
        }
    }
    
    private func scheduleNotification(for appliance: Appliance, reminder: Reminder) async {
        guard let expiryDate = appliance.warrantyExpiryDate,
              let applianceId = appliance.id else { return }
        
        // Calculate reminder date
        guard let reminderDate = Calendar.current.date(byAdding: .day, value: -reminder.daysBeforeExpiry, to: expiryDate) else {
            return
        }
        
        // Only schedule if reminder date is in the future
        guard reminderDate > Date() else { return }
        
        // Use custom time if available, otherwise use default reminder time
        let reminderTime = reminder.customTime ?? preferences.reminderTime
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
        
        // Combine reminder date with reminder time
        var finalReminderDate = calendar.date(bySettingHour: timeComponents.hour ?? 9, minute: timeComponents.minute ?? 0, second: 0, of: reminderDate) ?? reminderDate
        
        // If the combined time is in the past, move to next day
        if finalReminderDate <= Date() {
            finalReminderDate = calendar.date(byAdding: .day, value: 1, to: finalReminderDate) ?? finalReminderDate
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Warranty Reminder"
        
        // Use custom message if available, otherwise use default
        let message = reminder.message.isEmpty ? 
            "Your warranty for \(appliance.name ?? "appliance") expires on \(expiryDate.formatted(date: .abbreviated, time: .omitted))" :
            reminder.message.replacingOccurrences(of: "{appliance}", with: appliance.name ?? "appliance")
            .replacingOccurrences(of: "{expiryDate}", with: expiryDate.formatted(date: .abbreviated, time: .omitted))
            .replacingOccurrences(of: "{daysLeft}", with: "\(reminder.daysBeforeExpiry)")
        
        content.body = message
        content.sound = .default
        content.badge = 1
        
        // Add user info for deep linking
        content.userInfo = [
            "applianceId": applianceId.uuidString,
            "reminderType": "warranty",
            "daysBeforeExpiry": reminder.daysBeforeExpiry
        ]
        
        let triggerDate = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: finalReminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "\(applianceId.uuidString)-\(reminder.daysBeforeExpiry)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Scheduled notification for \(appliance.name ?? "appliance") \(reminder.displayText)")
        } catch {
            print("Error scheduling notification: \(error)")
        }
    }
    
    func cancelNotifications(for receipt: Receipt) {
        guard let receiptId = receipt.id else { return }
        
        // Cancel all reminders for this receipt
        for reminder in preferences.defaultReminders {
            let identifier = "\(receiptId.uuidString)-\(reminder.daysBeforeExpiry)"
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        }
    }
    
    func cancelNotifications(for appliance: Appliance) {
        guard let applianceId = appliance.id else { return }
        
        // Cancel all reminders for this appliance
        for reminder in preferences.defaultReminders {
            let identifier = "\(applianceId.uuidString)-\(reminder.daysBeforeExpiry)"
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        }
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    private func rescheduleAllNotifications() async {
        await MainActor.run {
            isUpdatingNotifications = true
        }
        
        // Cancel all existing notifications
        cancelAllNotifications()
        
        // Get all receipts and reschedule
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<Receipt> = Receipt.fetchRequest()
        
        do {
            let receipts = try context.fetch(request)
            for receipt in receipts {
                await scheduleNotifications(for: receipt)
            }
        } catch {
            print("Error fetching receipts for notifications: \(error)")
        }
        
        await MainActor.run {
            isUpdatingNotifications = false
        }
    }
    
    // MARK: - Private Methods
    
    private func savePreferences() {
        if let data = try? JSONEncoder().encode(preferences) {
            userDefaults.set(data, forKey: preferencesKey)
        }
    }
}

// MARK: - Reminder Management View
struct ReminderManagementView: View {
    @ObservedObject private var reminderManager = ReminderManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingCustomMessageEditor = false
    @State private var editingReminder: Reminder?
    @State private var customMessage: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.largeSpacing) {
                    // Header
                    headerSection
                    
                    // Reminder Settings
                    reminderSettingsSection
                    
                    // Custom Message
                    customMessageSection
                    
                    // Reminder Time
                    reminderTimeSection
                    
                    // Notification Toggle
                    notificationToggleSection
                }
                .padding(AppTheme.spacing)
            }
            .navigationTitle("Reminder Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingCustomMessageEditor) {
            CustomMessageEditorView(
                message: $customMessage,
                onSave: { newMessage in
                    reminderManager.updateCustomMessage(newMessage)
                }
            )
        }
        .sheet(item: $editingReminder) { reminder in
            ReminderMessageEditorView(
                reminder: reminder,
                onSave: { updatedReminder in
                    reminderManager.updateReminderMessage(updatedReminder, message: updatedReminder.message)
                }
            )
        }
        .onAppear {
            customMessage = reminderManager.preferences.customReminderMessage
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: AppTheme.spacing) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.primary)
            
            Text("Customize Your Reminders")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.text)
            
            Text("Set up multiple reminders with custom messages to never miss a warranty expiry")
                .font(.body)
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadius)
    }
    
    private var reminderSettingsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            Text("Reminder Schedule")
                .font(.headline)
                .foregroundColor(AppTheme.text)
            
            VStack(spacing: AppTheme.smallSpacing) {
                ForEach(reminderManager.preferences.defaultReminders) { reminder in
                    ReminderRowView(
                        reminder: reminder,
                        onToggle: {
                            reminderManager.toggleReminder(reminder)
                        },
                        onEditMessage: {
                            editingReminder = reminder
                        }
                    )
                }
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadius)
        }
    }
    
    private var customMessageSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            Text("Custom Message Template")
                .font(.headline)
                .foregroundColor(AppTheme.text)
            
            VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
                Text("Use placeholders: {appliance}, {expiryDate}, {daysLeft}")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
                
                Button(action: {
                    showingCustomMessageEditor = true
                }) {
                    HStack {
                        Text(customMessage.isEmpty ? "Add custom message..." : customMessage)
                            .foregroundColor(customMessage.isEmpty ? AppTheme.secondaryText : AppTheme.text)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        Image(systemName: "pencil")
                            .foregroundColor(AppTheme.primary)
                    }
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(AppTheme.cornerRadius)
                }
            }
        }
    }
    
    private var reminderTimeSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            Text("Reminder Time")
                .font(.headline)
                .foregroundColor(AppTheme.text)
            
            DatePicker(
                "Reminder Time",
                selection: Binding(
                    get: { reminderManager.preferences.reminderTime },
                    set: { reminderManager.updateReminderTime($0) }
                ),
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadius)
        }
    }
    
    private var notificationToggleSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            Text("Notifications")
                .font(.headline)
                .foregroundColor(AppTheme.text)
            
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
                    Text("Enable Notifications")
                        .foregroundColor(AppTheme.text)
                    
                    Text("Receive warranty reminders on your device")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { reminderManager.preferences.notificationsEnabled },
                    set: { reminderManager.toggleNotifications($0) }
                ))
                .labelsHidden()
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadius)
        }
    }
}

// MARK: - Reminder Row View
struct ReminderRowView: View {
    let reminder: Reminder
    let onToggle: () -> Void
    let onEditMessage: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
                Text(reminder.displayText)
                    .font(.headline)
                    .foregroundColor(AppTheme.text)
                
                Text(reminder.message.isEmpty ? "Default message" : reminder.message)
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(spacing: AppTheme.smallSpacing) {
                Toggle("", isOn: .constant(reminder.isEnabled))
                    .labelsHidden()
                    .onTapGesture {
                        onToggle()
                    }
                
                Button(action: onEditMessage) {
                    Image(systemName: "pencil")
                        .foregroundColor(AppTheme.primary)
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, AppTheme.smallSpacing)
    }
}

// MARK: - Custom Message Editor
struct CustomMessageEditorView: View {
    @Binding var message: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var tempMessage: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.largeSpacing) {
                VStack(alignment: .leading, spacing: AppTheme.spacing) {
                    Text("Custom Message Template")
                        .font(.headline)
                        .foregroundColor(AppTheme.text)
                    
                    Text("Use these placeholders in your message:")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                    
                    VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
                        Text("• {appliance} - Appliance name")
                        Text("• {expiryDate} - Warranty expiry date")
                        Text("• {daysLeft} - Days until expiry")
                    }
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
                }
                
                TextField("Enter your custom message...", text: $tempMessage, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
                
                Spacer()
            }
            .padding(AppTheme.spacing)
            .navigationTitle("Edit Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        message = tempMessage
                        onSave(tempMessage)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            tempMessage = message
        }
    }
}

// MARK: - Reminder Message Editor
struct ReminderMessageEditorView: View {
    let reminder: Reminder
    let onSave: (Reminder) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var tempMessage: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.largeSpacing) {
                VStack(alignment: .leading, spacing: AppTheme.spacing) {
                    Text("Edit \(reminder.displayText) Message")
                        .font(.headline)
                        .foregroundColor(AppTheme.text)
                    
                    Text("Use these placeholders in your message:")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                    
                    VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
                        Text("• {appliance} - Appliance name")
                        Text("• {expiryDate} - Warranty expiry date")
                        Text("• {daysLeft} - Days until expiry")
                    }
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
                }
                
                TextField("Enter your message...", text: $tempMessage, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
                
                Spacer()
            }
            .padding(AppTheme.spacing)
            .navigationTitle("Edit Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var updatedReminder = reminder
                        updatedReminder.message = tempMessage
                        onSave(updatedReminder)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            tempMessage = reminder.message
        }
    }
}
