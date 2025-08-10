//
//  NotificationPreferencesView.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI
import UserNotifications

struct NotificationPreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("notificationSound") private var notificationSound: String = "default"
    @AppStorage("notificationBadge") private var notificationBadge: Bool = true
    @AppStorage("notificationAlertStyle") private var alertStyle: String = "banner"
    @AppStorage("notificationGrouping") private var notificationGrouping: Bool = true
    @AppStorage("notificationPreview") private var notificationPreview: String = "when_unlocked"
    @AppStorage("quietHoursEnabled") private var quietHoursEnabled: Bool = false
    @AppStorage("quietHoursStart") private var quietHoursStart: Date = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
    @AppStorage("quietHoursEnd") private var quietHoursEnd: Date = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    
    @State private var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    @State private var showingPermissionAlert = false
    
    private let soundOptions = [
        ("default", "Default"),
        ("chime", "Chime"),
        ("glass", "Glass"),
        ("note", "Note"),
        ("bell", "Bell"),
        ("none", "None")
    ]
    
    private let alertStyleOptions = [
        ("banner", "Banner"),
        ("alert", "Alert"),
        ("none", "None")
    ]
    
    private let previewOptions = [
        ("always", "Always"),
        ("when_unlocked", "When Unlocked"),
        ("never", "Never")
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Notification Permission") {
                    HStack {
                        Text("Permission Status")
                        Spacer()
                        Text(permissionStatusText)
                            .foregroundColor(permissionStatusColor)
                    }
                    
                    if notificationPermissionStatus == .denied {
                        Button("Open Settings") {
                            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsUrl)
                            }
                        }
                        .foregroundColor(AppTheme.primary)
                    }
                }
                
                Section("Sound & Vibration") {
                    HStack {
                        Text("Notification Sound")
                        Spacer()
                        Picker("Sound", selection: $notificationSound) {
                            ForEach(soundOptions, id: \.0) { sound in
                                Text(sound.1).tag(sound.0)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    HStack {
                        Text("Vibration")
                        Spacer()
                        Toggle("", isOn: .constant(true))
                    }
                }
                
                Section("Display Options") {
                    HStack {
                        Text("Badge App Icon")
                        Spacer()
                        Toggle("", isOn: $notificationBadge)
                    }
                    
                    HStack {
                        Text("Alert Style")
                        Spacer()
                        Picker("Alert Style", selection: $alertStyle) {
                            ForEach(alertStyleOptions, id: \.0) { style in
                                Text(style.1).tag(style.0)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    HStack {
                        Text("Group Notifications")
                        Spacer()
                        Toggle("", isOn: $notificationGrouping)
                    }
                    
                    HStack {
                        Text("Notification Preview")
                        Spacer()
                        Picker("Preview", selection: $notificationPreview) {
                            ForEach(previewOptions, id: \.0) { preview in
                                Text(preview.1).tag(preview.0)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                Section("Quiet Hours") {
                    HStack {
                        Text("Enable Quiet Hours")
                        Spacer()
                        Toggle("", isOn: $quietHoursEnabled)
                    }
                    
                    if quietHoursEnabled {
                        HStack {
                            Text("Start Time")
                            Spacer()
                            DatePicker("", selection: $quietHoursStart, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                        }
                        
                        HStack {
                            Text("End Time")
                            Spacer()
                            DatePicker("", selection: $quietHoursEnd, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                        }
                        
                        Text("Notifications will be silenced during quiet hours")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Test Notifications") {
                    Button("Send Test Notification") {
                        sendTestNotification()
                    }
                    .foregroundColor(AppTheme.primary)
                }
            }
            .navigationTitle("Notification Preferences")
            .navigationBarTitleDisplayMode(.inline)
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
                }
            }
        }
        .onAppear {
            checkNotificationPermission()
        }
        .alert("Notification Permission Required", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To receive notifications, please enable them in Settings > Notifications > ReceiptLock")
        }
    }
    
    private var permissionStatusText: String {
        switch notificationPermissionStatus {
        case .authorized:
            return "Enabled"
        case .denied:
            return "Disabled"
        case .notDetermined:
            return "Not Determined"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Ephemeral"
        @unknown default:
            return "Unknown"
        }
    }
    
    private var permissionStatusColor: Color {
        switch notificationPermissionStatus {
        case .authorized:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        case .provisional:
            return .blue
        case .ephemeral:
            return .purple
        @unknown default:
            return .gray
        }
    }
    
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationPermissionStatus = settings.authorizationStatus
            }
        }
    }
    
    private func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is a test notification from ReceiptLock"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "test", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending test notification: \(error)")
            }
        }
    }
}

#Preview {
    NotificationPreferencesView()
}
