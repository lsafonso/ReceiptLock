//
//  DashboardView.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI
import CoreData
import UIKit

// MARK: - Sort Order Enum
enum SortOrder: String, CaseIterable {
    case recentlyAdded = "Recently Added"
    case expiringSoon = "Expiring Soon"
    case alphabetical = "Alphabetical"
    case brand = "Brand"
}

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Appliance.createdAt, ascending: false)],
        animation: .default)
    private var appliances: FetchedResults<Appliance>
    
    @StateObject private var profileManager = UserProfileManager.shared
    @State private var selectedSortOrder: SortOrder = .recentlyAdded
    @State private var animateFilters = false
    @State private var selectedCard: Int? = nil
    @State private var showingProfileEdit = false
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.background
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: AppTheme.largeSpacing) {
                    // Header
                    headerSection
                    
                    // Warranty Summary Card
                    warrantySummaryCard
                    
                    // Your Appliances Section
                    appliancesSection
                }
                .padding(AppTheme.spacing)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingProfileEdit) {
            ProfileEditView()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                    
                    Text(profileManager.currentProfile.name.isEmpty ? "User" : profileManager.currentProfile.name)
                        .font(.system(size: 34, weight: .regular, design: .default))
                        .foregroundColor(AppTheme.text)
                        .lineSpacing(-4)
                }
                
                Spacer()
                
                HStack(spacing: AppTheme.smallSpacing) {
                    Button(action: {}) {
                        Image(systemName: "bell.fill")
                            .font(.title2)
                            .foregroundColor(AppTheme.primary)
                    }
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    
                    Button(action: {
                        showingProfileEdit = true
                    }) {
                        AvatarView(
                            image: profileManager.getAvatarImage(),
                            size: 40,
                            showBorder: false
                        )
                    }
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                }
            }
        }
        .padding(.horizontal, AppTheme.spacing)
        .padding(.bottom, 6) // Add 6pt space below header
    }
    
    // MARK: - Warranty Summary Card
    private var warrantySummaryCard: some View {
        HStack(spacing: 0) {
            // All devices
            SummaryColumn(
                icon: "house.fill",
                value: "\(sortedAppliances.count)",
                caption: "Active devices"
            )
            
            // Divider
            Divider()
                .frame(height: 60)
                .foregroundColor(AppTheme.secondaryText.opacity(0.2))
            
            // Valid warranty
            SummaryColumn(
                icon: "checkmark.circle.fill",
                value: "\(validWarranties.count)",
                caption: "Valid warranty"
            )
            
            // Divider
            Divider()
                .frame(height: 60)
                .foregroundColor(AppTheme.secondaryText.opacity(0.2))
            
            // Expired warranty
            SummaryColumn(
                icon: "exclamationmark.triangle.fill",
                value: "\(expiredWarranties.count)",
                caption: "Expired warranty"
            )
        }
        .padding(AppTheme.spacing)
        .cardBackground()
    }
    
    // MARK: - Summary Column Component
    private struct SummaryColumn: View {
        let icon: String
        let value: String
        let caption: String
        
        var body: some View {
            VStack(alignment: .center, spacing: 6) {
                Image(systemName: icon)
                    .font(.title3) // Slightly reduced from title2
                    .foregroundColor(AppTheme.primary)
                
                Text(value)
                    .font(.title.weight(.black)) // Heavier weight for numbers
                    .foregroundColor(AppTheme.text)
                
                Text(caption)
                    .font(.caption) // Regular weight
                    .foregroundColor(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.largeSpacing)
        }
    }
    
    // MARK: - Appliances Section
    private var appliancesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            HStack {
                Text("Your Appliances")
                    .rlHeadline()
                
                Spacer()
                
                // Sorting Dropdown
                Menu {
                    ForEach(SortOrder.allCases, id: \.self) { sortOrder in
                        Button(action: {
                            selectedSortOrder = sortOrder
                        }) {
                            HStack {
                                Text(sortOrder.rawValue)
                                if selectedSortOrder == sortOrder {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AppTheme.primary)
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.caption)
                        Text(selectedSortOrder.rawValue)
                            .rlCaption()
                            .fontWeight(.medium)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundColor(AppTheme.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.primary.opacity(0.1))
                    .cornerRadius(AppTheme.smallCornerRadius)
                }
            }
            
            if sortedAppliances.isEmpty {
                EmptyStateView(
                    title: "No Appliances Yet",
                    message: "Start by adding your first appliance to track warranties.",
                    systemImage: "plus.circle"
                )
            } else {
                LazyVStack(spacing: AppTheme.spacing) {
                    ForEach(sortedAppliances, id: \.id) { appliance in
                        ExpandableApplianceCard(appliance: appliance)
                    }
                }
            }
            
            viewAllButton
        }
    }
    
    // MARK: - View All Button
    private var viewAllButton: some View {
        Button(action: {
            // Switch to Appliances tab (index 1)
            NotificationCenter.default.post(name: Notification.Name("switchToAppliancesTab"), object: nil)
        }) {
            HStack {
                Text("View All Appliances")
                    .rlHeadline()
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundColor(.white)
            .padding(AppTheme.largeSpacing)
            .background(AppTheme.primary)
            .cornerRadius(AppTheme.cornerRadius)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Computed Properties
    
    private var validWarranties: [Appliance] {
        let now = Date()
        return appliances.filter { appliance in
            guard let expiryDate = appliance.warrantyExpiryDate else { return false }
            return expiryDate > now
        }
    }
    
    private var expiredWarranties: [Appliance] {
        let now = Date()
        return appliances.filter { appliance in
            guard let expiryDate = appliance.warrantyExpiryDate else { return false }
            return expiryDate < now
        }
    }
    
    private var sortedAppliances: [Appliance] {
        // Filter out expired warranties - only show appliances with valid warranties
        let validAppliances = appliances.filter { appliance in
            guard let expiryDate = appliance.warrantyExpiryDate else { return true } // Show appliances without expiry date
            return expiryDate > Date() // Only show if warranty hasn't expired
        }
        
        switch selectedSortOrder {
        case .recentlyAdded:
            return validAppliances.sorted { appliance1, appliance2 in
                guard let date1 = appliance1.createdAt,
                      let date2 = appliance2.createdAt else { return false }
                return date1 > date2
            }
        case .expiringSoon:
            return validAppliances.sorted { appliance1, appliance2 in
                guard let expiry1 = appliance1.warrantyExpiryDate,
                      let expiry2 = appliance2.warrantyExpiryDate else { return false }
                return expiry1 < expiry2
            }
        case .alphabetical:
            return validAppliances.sorted { appliance1, appliance2 in
                (appliance1.name ?? "") < (appliance2.name ?? "")
            }
        case .brand:
            return validAppliances.sorted { appliance1, appliance2 in
                (appliance1.brand ?? "") < (appliance2.brand ?? "")
            }
        }
    }
}

// MARK: - Expandable Appliance Card
struct ExpandableApplianceCard: View {
    let appliance: Appliance
    @State private var isExpanded = false
    @State private var isPressed = false
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingActionSheet = false // Added for long press gesture
    @State private var isDeleting = false // Track deletion state to prevent multiple deletions
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        VStack(spacing: 2) {
            // Main card content with swipe actions applied to exactly the card height
            mainCardContent
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    // Edit action
                    Button(action: {
                        showingEditSheet = true
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: "pencil")
                                .font(.title3)
                            Text("Edit")
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxHeight: .infinity)
                    }
                    .tint(AppTheme.primary)
                    
                    // Delete action (direct deletion from swipe - no confirmation)
                    Button(role: .destructive, action: {
                        if !isDeleting {
                            deleteAppliance()
                        }
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: "trash")
                                .font(.title3)
                            Text("Delete")
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxHeight: .infinity)
                    }
                    .disabled(isDeleting)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    // Quick share action
                    Button(action: {
                        shareAppliance()
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title3)
                            Text("Share")
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxHeight: .infinity)
                    }
                    .tint(AppTheme.success)
                }
            
            // Expanded content
            if isExpanded {
                expandedContent
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditApplianceView(appliance: appliance)
        }
        .alert("Delete Appliance", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAppliance()
            }
        } message: {
            Text("Are you sure you want to delete '\(appliance.name ?? "this appliance")'? This action cannot be undone.")
        }
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(title: Text("Appliance Actions"), message: Text("Choose an action for \(appliance.name ?? "this appliance")"), buttons: [
                .default(Text("Edit")) { showingEditSheet = true },
                .default(Text("Share")) { shareAppliance() },
                .destructive(Text("Delete")) { showingDeleteAlert = true },
                .cancel()
            ])
        }
    }
    
    // MARK: - Main Card Content
    private var mainCardContent: some View {
        HStack(spacing: AppTheme.spacing) {
            // Appliance icon
            Image(systemName: getApplianceIcon())
                .font(.title2)
                .foregroundColor(getApplianceColor())
                .frame(width: 40, height: 40)
                .background(getApplianceColor().opacity(0.1))
                .cornerRadius(AppTheme.smallCornerRadius)
            
            // Appliance details
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(appliance.name ?? "Untitled Appliance")
                        .rlHeadline()
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Store Badge
                    Text(storeBadgeText)
                        .rlCaption2Strong()
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.primary)
                        .cornerRadius(4)
                        .accessibilityLabel("Store: \(appliance.brand ?? "Unknown")")
                        .help(appliance.brand ?? "Unknown")
                }
                
                HStack {
                    Text("Warranty expires: \(formattedExpiryDate)")
                        .rlCaption()
                        .fontWeight(.medium)
                        .foregroundColor(expiryStatusColor)
                    
                    Spacer()
                }
                
                // Progress bar
                ProgressView(value: progressValue, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: expiryStatusColor))
                    .frame(height: 4)
                
                // Swipe hint text
                HStack {
                    Spacer()
                    Text("Swipe for actions")
                        .rlCaption2Muted()
                        .opacity(0.5)
                        .italic()
                }
            }
            
            // Expandable chevron
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(AppTheme.primary)
                .rotationEffect(.degrees(isExpanded ? 0 : 0))
                .animation(AppTheme.springAnimation, value: isExpanded)
                .frame(width: 24, height: 24) // Fixed size for consistent tap target
                .background(Color.clear) // Ensure background is clear
                .onTapGesture {
                    withAnimation(AppTheme.springAnimation) {
                        isExpanded.toggle()
                        isPressed = true
                    }
                    
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(AppTheme.springAnimation) {
                            isPressed = false
                        }
                    }
                }
        }
        .padding(AppTheme.spacing)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .contentShape(Rectangle()) // Ensure hit testing matches visual bounds
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(AppTheme.springAnimation, value: isPressed)
        .shadow(color: AppTheme.secondaryText.opacity(0.1), radius: 2, x: 0, y: 1)
        .onLongPressGesture(minimumDuration: 0.5) {
            // Long press shows action sheet as alternative to swipe
            showingActionSheet = true
        }
    }
    
    // MARK: - Expanded Content
    private var expandedContent: some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.horizontal, AppTheme.spacing)
            
            VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
                // Brand and Model
                if let brand = appliance.brand, let model = appliance.model {
                    DetailRow(title: "Brand", value: brand)
                    DetailRow(title: "Model", value: model)
                }
                
                // Purchase Date
                if let purchaseDate = appliance.purchaseDate {
                    DetailRow(title: "Purchase Date", value: formatDate(purchaseDate))
                }
                
                // Warranty Duration
                if let purchaseDate = appliance.purchaseDate, let expiryDate = appliance.warrantyExpiryDate {
                    let duration = Calendar.current.dateComponents([.month, .day], from: purchaseDate, to: expiryDate)
                    let durationText = "\(duration.month ?? 0) months, \(duration.day ?? 0) days"
                    DetailRow(title: "Warranty Duration", value: durationText)
                }
                
                // Days Remaining
                if let expiryDate = appliance.warrantyExpiryDate {
                    let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
                    let statusText = daysRemaining > 0 ? "\(daysRemaining) days remaining" : "Expired"
                    DetailRow(title: "Status", value: statusText, valueColor: expiryStatusColor)
                }
                
                // Serial Number
                if let serialNumber = appliance.serialNumber, !serialNumber.isEmpty {
                    DetailRow(title: "Serial Number", value: serialNumber)
                }
                
                // Notes
                if let notes = appliance.notes, !notes.isEmpty {
                    DetailRow(title: "Notes", value: notes)
                }
            }
            .padding(.horizontal, AppTheme.spacing)
            .padding(.vertical, AppTheme.spacing)
        }
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .padding(.top, 1) // Add small gap to prevent overlap
        .transition(.asymmetric(
            insertion: .scale(scale: 0.95).combined(with: .opacity),
            removal: .scale(scale: 0.95).combined(with: .opacity)
        ))
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
        } else if title.contains("camera") {
            return "camera"
        } else if title.contains("tablet") {
            return "ipad"
        } else {
            return "gearshape"
        }
    }
    
    private func getApplianceColor() -> Color {
        let title = appliance.name?.lowercased() ?? ""
        
        if title.contains("laptop") || title.contains("computer") || title.contains("mobile") || title.contains("phone") || title.contains("tablet") || title.contains("watch") {
            return .indigo
        } else if title.contains("camera") {
            return .gray
        } else {
            return AppTheme.primary
        }
    }
    
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
    
    private func formatDate(_ date: Date) -> String {
        return FormatterStore.expiryShort.string(from: date)
    }
    
    // MARK: - Action Methods
    
    /// Shares appliance information
    private func shareAppliance() {
        let applianceInfo = """
        Appliance: \(appliance.name ?? "Unknown")
        Brand: \(appliance.brand ?? "Unknown")
        Model: \(appliance.model ?? "Unknown")
        Warranty Expires: \(formattedExpiryDate)
        Purchase Date: \(appliance.purchaseDate != nil ? formatDate(appliance.purchaseDate!) : "Unknown")
        Serial Number: \(appliance.serialNumber ?? "Not provided")
        Notes: \(appliance.notes ?? "No additional notes")
        """
        
        let activityVC = UIActivityViewController(
            activityItems: [applianceInfo],
            applicationActivities: nil
        )
        
        // Present the share sheet
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    /// Deletes the appliance from Core Data
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
}

// MARK: - Detail Row
struct DetailRow: View {
    let title: String
    let value: String
    let valueColor: Color
    
    init(title: String, value: String, valueColor: Color = AppTheme.text) {
        self.title = title
        self.value = value
        self.valueColor = valueColor
    }
    
    var body: some View {
        HStack {
            Text(title)
                .rlCaption()
                .fontWeight(.medium)
                .foregroundColor(AppTheme.secondaryText)
            
            Spacer()
            
            Text(value)
                .rlCaptionStrong()
                .foregroundColor(valueColor)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    DashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 