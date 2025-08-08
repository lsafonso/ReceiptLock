//
//  DashboardView.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI
import CoreData

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Receipt.createdAt, ascending: false)],
        animation: .default)
    private var receipts: FetchedResults<Receipt>
    
    @State private var showingAddAppliance = false
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
                        
                        // View All Appliances Button
                        viewAllButton
                    }
                    .padding(AppTheme.spacing)
                }
            }
            .navigationBarHidden(true)
        }
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
                
                Text("\(receipts.count)")
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
            Text("Your Appliances")
                .font(.headline.weight(.semibold))
                .foregroundColor(AppTheme.text)
            
            if receipts.isEmpty {
                EmptyStateView(
                    title: "No Appliances Yet",
                    message: "Start by adding your first appliance to track warranties.",
                    systemImage: "plus.circle",
                    actionTitle: "Add Appliance",
                    action: { showingAddAppliance = true }
                )
            } else {
                LazyVStack(spacing: AppTheme.smallSpacing) {
                    ForEach(Array(receipts.prefix(3)), id: \.id) { receipt in
                        NavigationLink(destination: ApplianceDetailView(receipt: receipt)) {
                            ApplianceRowView(receipt: receipt)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
    
    // MARK: - View All Button
    private var viewAllButton: some View {
        Button(action: {}) {
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
    
    private var validWarranties: [Receipt] {
        let now = Date()
        return receipts.filter { receipt in
            guard let expiryDate = receipt.expiryDate else { return false }
            return expiryDate > now
        }
    }
    
    private var expiredWarranties: [Receipt] {
        let now = Date()
        return receipts.filter { receipt in
            guard let expiryDate = receipt.expiryDate else { return false }
            return expiryDate < now
        }
    }
}

#Preview {
    DashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 