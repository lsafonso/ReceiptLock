//
//  DashboardView.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI
import CoreData

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
    
    @State private var showingAddAppliance = false
    @State private var selectedSortOrder: SortOrder = .recentlyAdded
    @State private var selectedCard: Int? = nil
    
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
                        
                        // Warranty Summary Card
                        warrantySummaryCard
                        
                        // Your Appliances Section
                        appliancesSection
                    }
                    .padding(AppTheme.spacing)
                }
            }
            .navigationBarHidden(true)
        }
        .overlay(
            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showingAddAppliance = true }) {
                        Image(systemName: "plus")
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(AppTheme.primary)
                            .clipShape(Circle())
    
                    }
                    .padding(.trailing, AppTheme.spacing)
                    .padding(.bottom, AppTheme.spacing)
                }
            }
        )
        .sheet(isPresented: $showingAddAppliance) {
            AddApplianceView()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                    
                    Text(UserProfileManager.shared.currentProfile.name.isEmpty ? "User" : UserProfileManager.shared.currentProfile.name)
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(AppTheme.text)
                }
                
                Spacer()
                
                HStack(spacing: AppTheme.smallSpacing) {
                    Button(action: {}) {
                        Image(systemName: "bell.fill")
                            .font(.title2)
                            .foregroundColor(AppTheme.primary)
                    }
                    
                    Button(action: {
                        // Show profile edit sheet
                    }) {
                        AvatarView(
                            image: UserProfileManager.shared.getAvatarImage(),
                            size: 40,
                            showBorder: false
                        )
                    }
                }
            }
        }
        .padding(.horizontal, AppTheme.spacing)
    }
    
    // MARK: - Warranty Summary Card
    private var warrantySummaryCard: some View {
        HStack(spacing: 0) {
            // All devices
            VStack(spacing: AppTheme.smallSpacing) {
                Image(systemName: "house.fill")
                    .font(.title2)
                    .foregroundColor(AppTheme.primary)
                
                Text("\(appliances.count)")
                    .font(.title.weight(.bold))
                    .foregroundColor(AppTheme.text)
                
                Text("All devices")
                    .font(.caption.weight(.medium))
                    .foregroundColor(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.largeSpacing)
            
            // Divider
            Rectangle()
                .frame(width: 1, height: 60)
                .foregroundColor(AppTheme.secondaryText.opacity(0.3))
            
            // Valid warranty
            VStack(spacing: AppTheme.smallSpacing) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(AppTheme.primary)
                
                Text("\(validWarranties.count)")
                    .font(.title.weight(.bold))
                    .foregroundColor(AppTheme.text)
                
                Text("Valid warranty")
                    .font(.caption.weight(.medium))
                    .foregroundColor(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.largeSpacing)
            
            // Divider
            Rectangle()
                .frame(width: 1, height: 60)
                .foregroundColor(AppTheme.secondaryText.opacity(0.3))
            
            // Expired warranty
            VStack(spacing: AppTheme.smallSpacing) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(AppTheme.primary)
                
                Text("\(expiredWarranties.count)")
                    .font(.title.weight(.bold))
                    .foregroundColor(AppTheme.text)
                
                Text("Expired warranty")
                    .font(.caption.weight(.medium))
                    .foregroundColor(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.largeSpacing)
        }
        .padding(AppTheme.spacing)
        .cardBackground()
    }
    
    // MARK: - Appliances Section
    private var appliancesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            HStack {
                Text("Your Appliances")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(AppTheme.text)
                
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
                            .font(.caption.weight(.medium))
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
                    systemImage: "plus.circle",
                    actionTitle: "Add Appliance",
                    action: { showingAddAppliance = true }
                )
            } else {
                LazyVStack(spacing: AppTheme.smallSpacing) {
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
                    .font(.headline.weight(.semibold))
                
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
        switch selectedSortOrder {
        case .recentlyAdded:
            return appliances.sorted { appliance1, appliance2 in
                guard let date1 = appliance1.createdAt,
                      let date2 = appliance2.createdAt else { return false }
                return date1 > date2
            }
        case .expiringSoon:
            return appliances.sorted { appliance1, appliance2 in
                guard let expiry1 = appliance1.warrantyExpiryDate,
                      let expiry2 = appliance2.warrantyExpiryDate else { return false }
                return expiry1 < expiry2
            }
        case .alphabetical:
            return appliances.sorted { appliance1, appliance2 in
                (appliance1.name ?? "") < (appliance2.name ?? "")
            }
        case .brand:
            return appliances.sorted { appliance1, appliance2 in
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
    
    var body: some View {
        VStack(spacing: 0) {
            // Main card content (always visible)
            Button(action: {
                withAnimation(AppTheme.springAnimation) {
                    isExpanded.toggle()
                }
                
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }) {
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
                                .font(.headline.weight(.semibold))
                                .foregroundColor(AppTheme.text)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            // Store Badge
                            Text(storeBadgeText)
                                .font(.caption2.weight(.bold))
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
                                .font(.caption.weight(.medium))
                                .foregroundColor(expiryStatusColor)
                            
                            Spacer()
                        }
                        
                        // Progress bar
                        ProgressView(value: progressValue, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: expiryStatusColor))
                            .frame(height: 4)
                    }
                    
                    // Expandable chevron
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(AppTheme.primary)
                        .rotationEffect(.degrees(isExpanded ? 0 : 0))
                        .animation(AppTheme.springAnimation, value: isExpanded)
                }
                .padding(AppTheme.spacing)
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.cornerRadius)
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .animation(AppTheme.springAnimation, value: isPressed)
            }
            .buttonStyle(PlainButtonStyle())
            .onTapGesture {
                withAnimation(AppTheme.springAnimation) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(AppTheme.springAnimation) {
                        isPressed = false
                    }
                }
            }
            
            // Expanded content
            if isExpanded {
                VStack(spacing: AppTheme.spacing) {
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
                    .padding(.bottom, AppTheme.spacing)
                }
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.cornerRadius)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .scale(scale: 0.95).combined(with: .opacity)
                ))
            }
        }
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
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        return formatter.string(from: expiryDate)
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
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
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
                .font(.caption.weight(.medium))
                .foregroundColor(AppTheme.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundColor(valueColor)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    DashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 