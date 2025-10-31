//
//  ApplianceDetailView.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI

struct ApplianceDetailView: View {
    let appliance: Appliance
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.largeSpacing) {
                // Header with image
                headerSection
                
                // Appliance details
                detailsSection
                
                // Warranty information
                warrantySection
                
                // Actions
                actionsSection
            }
            .padding(AppTheme.spacing)
        }
        .background(AppTheme.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Edit") {
                        showingEditSheet = true
                    }
                    
                    Button("Share", action: shareAppliance)
                    
                    Divider()
                    
                    Button("Delete", role: .destructive) {
                        showingDeleteAlert = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(AppTheme.primary)
                }
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
            Text("Are you sure you want to delete this appliance? This action cannot be undone.")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(spacing: AppTheme.spacing) {
            // Appliance icon - smaller size
            Image(systemName: getApplianceIcon())
                .font(.system(size: 40))
                .foregroundColor(getApplianceColor())
                .frame(width: 60, height: 60)
                .background(getApplianceColor().opacity(0.1))
                .cornerRadius(AppTheme.cornerRadius)
            
            VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
                Text(appliance.name ?? "Untitled Appliance")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(AppTheme.text)
                    .lineLimit(2)
                
                if let model = appliance.model, !model.isEmpty {
                    Text(model)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                } else {
                    Text(appliance.brand ?? "Unknown Brand")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
            
            Spacer()
        }
        .padding(AppTheme.spacing)
        .cardBackground()
    }
    
    // MARK: - Details Section
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            VStack(spacing: AppTheme.smallSpacing) {
                ApplianceInfoRow(title: "Purchase Date", value: formattedPurchaseDate)
                ApplianceInfoRow(title: "Price", value: formattedPrice)
                ApplianceInfoRow(title: "Warranty Duration", value: "\(appliance.warrantyMonths) months")
                ApplianceInfoRow(title: "Added", value: formattedCreatedDate)
            }
        }
        .padding(AppTheme.spacing)
        .cardBackground()
    }
    
    // MARK: - Warranty Section
    private var warrantySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            Text("Warranty Status")
                .font(.headline.weight(.semibold))
                .foregroundColor(AppTheme.text)
            
            VStack(spacing: AppTheme.spacing) {
                // Status indicator
                HStack {
                    Circle()
                        .fill(warrantyStatusColor)
                        .frame(width: 12, height: 12)
                    
                    Text(warrantyStatusText)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(warrantyStatusColor)
                    
                    Spacer()
                }
                
                // Progress bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Warranty Progress")
                            .font(.caption.weight(.medium))
                            .foregroundColor(AppTheme.secondaryText)
                        
                        Spacer()
                        
                        Text("\(Int(progressValue * 100))%")
                            .font(.caption.weight(.medium))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    
                    ProgressView(value: progressValue, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: warrantyStatusColor))
                        .frame(height: 8)
                }
                
                // Expiry date
                if appliance.warrantyExpiryDate != nil {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                        
                        Text("Expires on \(formattedExpiryDate)")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(AppTheme.spacing)
        .cardBackground()
    }
    
    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(spacing: AppTheme.spacing) {
            Button(action: shareAppliance) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .symbolRenderingMode(.monochrome)
                    Text("Share Appliance")
                }
                .foregroundColor(AppTheme.onPrimary)
                .frame(maxWidth: .infinity)
                .padding(AppTheme.spacing)
                .background(AppTheme.primary)
                .cornerRadius(AppTheme.cornerRadius)
            }
            
            Button(action: { showingEditSheet = true }) {
                HStack {
                    Image(systemName: "pencil")
                    Text("Edit Appliance")
                }
                .frame(maxWidth: .infinity)
                .padding(AppTheme.spacing)
                .background(AppTheme.primary.opacity(0.1))
                .foregroundColor(AppTheme.primary)
                .cornerRadius(AppTheme.cornerRadius)
            }
        }
        .padding(AppTheme.spacing)
        .cardBackground()
    }
    
    // MARK: - Computed Properties
    
    private var warrantyStatusColor: Color {
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
    
    private var warrantyStatusText: String {
        guard let expiryDate = appliance.warrantyExpiryDate else { return "Unknown Status" }
        
        let now = Date()
        let daysUntilExpiry = Calendar.current.dateComponents([.day], from: now, to: expiryDate).day ?? 0
        
        if expiryDate < now {
            return "Warranty Expired"
        } else if daysUntilExpiry <= 7 {
            return "Expiring Soon"
        } else if daysUntilExpiry <= 30 {
            return "Expiring in \(daysUntilExpiry) days"
        } else {
            return "Warranty Active"
        }
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
    
    private var formattedPurchaseDate: String {
        guard let purchaseDate = appliance.purchaseDate else { return "Unknown" }
        
        return FormatterStore.expiryShort.string(from: purchaseDate)
    }
    
    private var formattedExpiryDate: String {
        guard let expiryDate = appliance.warrantyExpiryDate else { return "Unknown" }
        
        return FormatterStore.expiryShort.string(from: expiryDate)
    }
    
    private var formattedPrice: String {
        return appliance.price.formatted(.currency(code: CurrencyManager.shared.currencyCode))
    }
    
    private var formattedCreatedDate: String {
        return FormatterStore.expiryShort.string(from: appliance.createdAt ?? Date())
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
    
    private func shareAppliance() {
        let text = """
        Appliance: \(appliance.name ?? "Unknown")
        Brand: \(appliance.brand ?? "Unknown")
        Price: \(formattedPrice)
        Warranty: \(appliance.warrantyMonths) months
        Expires: \(formattedExpiryDate)
        """
        
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    private func deleteAppliance() {
        guard let viewContext = appliance.managedObjectContext else {
            print("❌ No managed object context available")
            return
        }
        
        print("🗑️ Deleting appliance: \(appliance.name ?? "Unknown")")
        
        viewContext.delete(appliance)
        
        do {
            try viewContext.save()
            print("✅ Appliance deleted successfully")
            
            // Haptic feedback for successful delete
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            // Dismiss the view
            dismiss()
        } catch {
            print("❌ Error deleting appliance: \(error)")
            
            // Haptic feedback for error
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
        }
    }
}

// MARK: - Appliance Info Row
struct ApplianceInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(AppTheme.text)
        }
    }
}


