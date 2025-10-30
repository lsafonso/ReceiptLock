//
//  ApplianceRowView.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI

struct ApplianceRowView: View {
    let appliance: Appliance
    @State private var isPressed = false
    @State private var showPulse = false
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingActionSheet = false // Added for long press gesture
    @State private var isDeleting = false // Track deletion state to prevent multiple deletions
    @AppStorage("hasSeenSwipeHint") private var hasSeenSwipeHint = false
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        // Main container with swipe actions applied directly
        HStack(spacing: AppTheme.spacing) {
            // Appliance icon
            Image(systemName: getApplianceIcon())
                .font(.title2)
                .foregroundColor(getApplianceColor())
                .frame(width: 40, height: 40)
                .background(getApplianceColor().opacity(0.1))
                .cornerRadius(AppTheme.smallCornerRadius)
            
            // Appliance details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(appliance.name ?? "Untitled Appliance")
                        .rlHeadline()
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Store Badge with filled pill style
                    Text(storeBadgeText)
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.white) // Explicit white text for contrast
                        .lineLimit(1)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(primaryDark)
                        )
                        .accessibilityLabel("Store: \(appliance.brand ?? "Unknown")")
                        .help(appliance.brand ?? "Unknown")
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        // Status icon for color-blind users
                        Image(systemName: statusIcon)
                            .font(.caption2)
                            .foregroundColor(AppTheme.secondaryText)
                        
                        Text("Expires \(formattedExpiryDate)")
                            .rlCaption()
                            .fontWeight(.medium)
                            .foregroundColor(expiryStatusColor)
                        
                        Spacer()
                        
                        // Subtle swipe hint indicator
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.left")
                                .font(.caption2)
                                .foregroundColor(AppTheme.secondaryText.opacity(0.6))
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                                .foregroundColor(AppTheme.secondaryText.opacity(0.6))
                        }
                        .opacity(0.7)
                    }
                    
                    // Custom progress bar
                    CustomProgressBar(
                        value: progressValue,
                        color: expiryStatusColor
                    )
                }
                
                // Swipe hint text (only show on first unseen card)
                if !hasSeenSwipeHint {
                    HStack {
                        Spacer()
                        Text("Swipe for actions")
                            .rlCaption2Muted()
                            .opacity(0.5)
                            .italic()
                    }
                    .transition(.opacity)
                }
            }
            
            // Chevron with expanded tap target (44×44pt minimum for accessibility)
            ZStack {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(AppTheme.secondaryText)
                    .rotationEffect(.degrees(isPressed ? 90 : 0))
                    .animation(AppTheme.springAnimation, value: isPressed)
            }
            .frame(width: 44, height: 44) // Minimum 44×44pt tap target for accessibility
            .contentShape(Rectangle()) // Ensure entire area is tappable
            .onTapGesture {
                    withAnimation(AppTheme.springAnimation) {
                        isPressed = true
                    }
                    
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    // Show pulse for urgent items
                    if isUrgent {
                        showPulse = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            showPulse = false
                        }
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(AppTheme.springAnimation) {
                            isPressed = false
                        }
                    }
                }
        }
        .padding(.horizontal, AppTheme.spacing)
        .padding(.vertical, AppTheme.spacing + 2) // Added 2pt vertical padding
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(
            color: .black.opacity(AppTheme.shadowOpacity),
            radius: isPressed ? AppTheme.shadowRadius * 0.7 : AppTheme.shadowRadius,
            x: AppTheme.shadowOffset.width,
            y: isPressed ? AppTheme.shadowOffset.height * 0.7 : AppTheme.shadowOffset.height
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(AppTheme.springAnimation, value: isPressed)
        .contentShape(Rectangle()) // Ensure the entire area is recognized for swipe gestures
        .background(Color.clear) // Ensure background doesn't interfere
        .onLongPressGesture(minimumDuration: 0.5) {
            // Long press shows action sheet as alternative to swipe
            showingActionSheet = true
        }
        .onAppear {
            // Show pulse animation for urgent items on appear
            if isUrgent {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showPulse = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        showPulse = false
                    }
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            // Edit action
            Button(action: {
                showingEditSheet = true
            }) {
                Label("Edit", systemImage: "pencil")
            }
            .tint(AppTheme.primary)
            
            // Delete action (direct deletion from swipe - no confirmation)
            Button(role: .destructive, action: {
                if !isDeleting {
                    // Mark hint as seen after first swipe
                    if !hasSeenSwipeHint {
                        hasSeenSwipeHint = true
                        
                        // Haptic feedback for first swipe
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                    }
                    
                    deleteAppliance()
                }
            }) {
                Label("Delete", systemImage: "trash")
            }
            .disabled(isDeleting)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            // Quick share action
            Button(action: {
                // Mark hint as seen after first swipe
                if !hasSeenSwipeHint {
                    hasSeenSwipeHint = true
                    
                    // Haptic feedback for first swipe
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
                
                shareAppliance()
            }) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .tint(AppTheme.secondary)
        }
        .allowsHitTesting(true) // Ensure the view can receive gestures
    }
    
    // MARK: - Action Methods
    
    private func deleteAppliance() {
        // Prevent multiple simultaneous deletions
        guard !isDeleting else { return }
        isDeleting = true
        
        // Cancel any scheduled notifications
        NotificationManager.shared.cancelNotification(for: appliance)
        
        // Delete associated file if exists
        if let fileName = appliance.name {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsPath.appendingPathComponent("receipts").appendingPathComponent(fileName)
            
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        // Defer the deletion to the next run loop to ensure swipe UI has fully dismissed
        DispatchQueue.main.async {
            self.viewContext.delete(self.appliance)
            
            do {
                try self.viewContext.save()
                
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                // Reset deletion state
                DispatchQueue.main.async {
                    self.isDeleting = false
                }
            } catch {
                print("Error deleting appliance: \(error)")
                
                // Haptic feedback for error
                let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                impactFeedback.impactOccurred()
                
                // Reset deletion state
                DispatchQueue.main.async {
                    self.isDeleting = false
                }
            }
        }
    }
    
    private func shareAppliance() {
        // Create share content
        let title = appliance.name ?? "Appliance"
        let brand = appliance.brand ?? "Unknown Brand"
        let model = appliance.model ?? "Unknown Model"
        let expiryDate = formattedExpiryDate
        
        let shareText = """
        Appliance: \(title)
        Brand: \(brand)
        Model: \(model)
        Expires: \(expiryDate)
        
        Shared from Appliance Warranty Tracker
        """
        
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    // MARK: - Computed Properties
    
    private var storeBadgeText: String {
        guard let storeName = appliance.brand, !storeName.isEmpty, storeName != "Unknown" else {
            return "Unknown"
        }
        
        if storeName.count <= 8 {
            return storeName
        } else {
            let truncated = String(storeName.prefix(8))
            return "\(truncated)…"
        }
    }
    
    private var expiryStatusColor: Color {
        guard let expiryDate = appliance.warrantyExpiryDate else { return AppTheme.secondaryText }
        
        let now = Date()
        let daysUntilExpiry = Calendar.current.dateComponents([.day], from: now, to: expiryDate).day ?? 0
        
        if expiryDate < now {
            return AppTheme.error
        } else if daysUntilExpiry <= 7 {
            return AppTheme.error
        } else if daysUntilExpiry <= 30 {
            return AppTheme.warning
        } else {
            return AppTheme.success
        }
    }
    
    private var formattedExpiryDate: String {
        guard let expiryDate = appliance.warrantyExpiryDate else { return "Unknown" }
        
        return FormatterStore.expiryShort.string(from: expiryDate)
    }
    
    private var progressValue: Double {
        guard let purchaseDate = appliance.purchaseDate,
              let expiryDate = appliance.warrantyExpiryDate else { return 0.0 }
        
        let now = Date()
        let totalDuration = expiryDate.timeIntervalSince(purchaseDate)
        let elapsedDuration = now.timeIntervalSince(purchaseDate)
        
        let progress = elapsedDuration / totalDuration
        return max(0.0, min(1.0, progress))
    }
    
    private var isUrgent: Bool {
        guard let expiryDate = appliance.warrantyExpiryDate else { return false }
        
        let now = Date()
        let daysUntilExpiry = Calendar.current.dateComponents([.day], from: now, to: expiryDate).day ?? 0
        
        return expiryDate < now || daysUntilExpiry <= 7
    }
    
    // Status icon for color-blind accessibility
    private var statusIcon: String {
        guard let expiryDate = appliance.warrantyExpiryDate else { return "circle" }
        
        let now = Date()
        let daysUntilExpiry = Calendar.current.dateComponents([.day], from: now, to: expiryDate).day ?? 0
        
        if expiryDate < now || daysUntilExpiry <= 7 {
            return "xmark.octagon.fill" // Expired or urgent
        } else if daysUntilExpiry <= 30 {
            return "exclamationmark.triangle.fill" // Expiring soon
        } else {
            return "checkmark.circle.fill" // Valid
        }
    }
    
    // Darkened primary color for better contrast with white text
    private var primaryDark: Color {
        // Reduce brightness by 15% for better WCAG AA contrast
        // Original: Color(red: 51/255, green: 102/255, blue: 102/255)
        return Color(red: 43/255, green: 87/255, blue: 87/255)
    }
    
    // MARK: - Helper Methods
    
    private func getApplianceIcon() -> String {
        let title = appliance.name?.lowercased() ?? ""
        
        if title.contains("laptop") || title.contains("computer") {
            return "laptopcomputer"
        } else if title.contains("mobile") || title.contains("phone") {
            return "iphone"
        } else if title.contains("watch") {
            return "applewatch"
        } else if title.contains("tablet") || title.contains("ipad") {
            return "ipad"
        } else if title.contains("air") && title.contains("conditioner") {
            return "snowflake"
        } else if title.contains("refrigerator") || title.contains("fridge") {
            return "thermometer.snowflake"
        } else if title.contains("washing") || title.contains("washer") {
            return "washer"
        } else if title.contains("microwave") {
            return "microwave"
        } else if title.contains("television") || title.contains("tv") {
            return "tv"
        } else if title.contains("camera") {
            return "camera"
        } else if title.contains("speaker") || title.contains("audio") {
            return "speaker"
        } else if title.contains("headphone") {
            return "headphones"
        } else if title.contains("printer") {
            return "printer"
        } else if title.contains("monitor") || title.contains("display") {
            return "display"
        } else if title.contains("keyboard") {
            return "keyboard"
        } else {
            return "gearshape"
        }
    }
    
    private func getApplianceColor() -> Color {
        let title = appliance.name?.lowercased() ?? ""
        
        if title.contains("laptop") || title.contains("computer") || title.contains("mobile") || title.contains("phone") || title.contains("tablet") || title.contains("watch") {
            return .indigo
        } else if title.contains("air") && title.contains("conditioner") {
            return .blue
        } else if title.contains("refrigerator") || title.contains("fridge") {
            return .teal
        } else if title.contains("washing") || title.contains("washer") {
            return .cyan
        } else if title.contains("microwave") {
            return .brown
        } else if title.contains("television") || title.contains("tv") {
            return .mint
        } else if title.contains("camera") {
            return .gray
        } else if title.contains("speaker") || title.contains("audio") || title.contains("headphone") {
            return .purple
        } else if title.contains("printer") {
            return .black
        } else if title.contains("monitor") || title.contains("display") {
            return .mint
        } else if title.contains("keyboard") {
            return .gray
        } else {
            return AppTheme.primary
        }
    }
}

// MARK: - Custom Progress Bar
struct CustomProgressBar: View {
    let value: Double
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track with subtle opacity
                Capsule()
                    .fill(color.opacity(0.22))
                    .frame(height: 7)
                
                // Progress fill
                Capsule()
                    .fill(color)
                    .frame(width: geometry.size.width * CGFloat(value), height: 7)
            }
        }
        .frame(height: 7)
    }
}

// MARK: - Preview
#Preview {
    // Note: This is a simplified preview as ApplianceRowView requires Core Data context
    ZStack {
        AppTheme.background
        Text("ApplianceRowView Preview")
            .foregroundColor(AppTheme.text)
    }
}

