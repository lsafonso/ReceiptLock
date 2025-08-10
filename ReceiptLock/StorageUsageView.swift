//
//  StorageUsageView.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI

struct StorageUsageView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var storageData: StorageData = StorageData(
        totalUsed: 0.0,
        availableSpace: 0.0,
        receiptImages: 0.0,
        appData: 0.0,
        cache: 0.0,
        other: 0.0
    )
    @State private var showingCleanupOptions = false
    @State private var isCleaningUp = false
    @State private var cleanupProgress: Double = 0.0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.largeSpacing) {
                    // Storage Overview
                    storageOverviewSection
                    
                    // Storage Breakdown
                    storageBreakdownSection
                    
                    // Cleanup Options
                    cleanupOptionsSection
                    
                    // Storage Tips
                    storageTipsSection
                }
                .padding(AppTheme.spacing)
            }
            .navigationTitle("Storage Usage")
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
            loadStorageData()
        }
        .sheet(isPresented: $showingCleanupOptions) {
            CleanupOptionsView { cleanupType in
                performCleanup(cleanupType)
            }
        }
    }
    
    // MARK: - Storage Overview Section
    
    private var storageOverviewSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(AppTheme.primary)
                    .font(.title2)
                
                Text("Storage Overview")
                    .font(.headline)
                
                Spacer()
            }
            
            VStack(spacing: AppTheme.spacing) {
                // Storage Progress Bar
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Used: \(String(format: "%.1f", storageData.totalUsed)) MB")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(String(format: "%.1f", storageData.usagePercentage))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: storageData.usagePercentage / 100)
                        .progressViewStyle(LinearProgressViewStyle())
                        .accentColor(storageData.usagePercentage > 80 ? .red : AppTheme.primary)
                }
                
                // Storage Stats
                HStack {
                    StorageStatCard(
                        title: "Total Used",
                        value: "\(String(format: "%.1f", storageData.totalUsed)) MB",
                        icon: "externaldrive.fill",
                        color: .blue
                    )
                    
                    StorageStatCard(
                        title: "Available",
                        value: "\(String(format: "%.1f", storageData.availableSpace)) MB",
                        icon: "externaldrive",
                        color: .green
                    )
                }
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadius)
    }
    
    // MARK: - Storage Breakdown Section
    
    private var storageBreakdownSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundColor(AppTheme.primary)
                    .font(.title2)
                
                Text("Storage Breakdown")
                    .font(.headline)
                
                Spacer()
            }
            
            VStack(spacing: AppTheme.smallSpacing) {
                StorageBreakdownRow(
                    title: "Receipt Images",
                    size: storageData.receiptImages,
                    percentage: storageData.receiptImagesPercentage,
                    icon: "photo.fill",
                    color: .blue
                )
                
                StorageBreakdownRow(
                    title: "App Data",
                    size: storageData.appData,
                    percentage: storageData.appDataPercentage,
                    icon: "doc.fill",
                    color: .green
                )
                
                StorageBreakdownRow(
                    title: "Cache",
                    size: storageData.cache,
                    percentage: storageData.cachePercentage,
                    icon: "clock.fill",
                    color: Color(red: 230/255, green: 154/255, blue: 100/255)
                )
                
                StorageBreakdownRow(
                    title: "Other",
                    size: storageData.other,
                    percentage: storageData.otherPercentage,
                    icon: "ellipsis.circle.fill",
                    color: .gray
                )
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadius)
    }
    
    // MARK: - Cleanup Options Section
    
    private var cleanupOptionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            HStack {
                Image(systemName: "trash.fill")
                    .foregroundColor(AppTheme.primary)
                    .font(.title2)
                
                Text("Cleanup Options")
                    .font(.headline)
                
                Spacer()
            }
            
            VStack(spacing: AppTheme.smallSpacing) {
                Button("Clean Up Storage") {
                    showingCleanupOptions = true
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                
                if isCleaningUp {
                    VStack(spacing: 8) {
                        ProgressView(value: cleanupProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                        
                        Text("Cleaning up... \(Int(cleanupProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadius)
    }
    
    // MARK: - Storage Tips Section
    
    private var storageTipsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(AppTheme.primary)
                    .font(.title2)
                
                Text("Storage Tips")
                    .font(.headline)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
                StorageTipRow(
                    icon: "photo",
                    title: "Compress Images",
                    description: "Enable auto-compression to reduce image file sizes"
                )
                
                StorageTipRow(
                    icon: "clock",
                    title: "Regular Cleanup",
                    description: "Clean up old cache files monthly"
                )
                
                StorageTipRow(
                    icon: "icloud",
                    title: "Use iCloud",
                    description: "Store receipts in iCloud to save local space"
                )
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadius)
    }
    
    // MARK: - Helper Methods
    
    private func loadStorageData() {
        // Simulate loading storage data
        storageData = StorageData(
            totalUsed: 245.7,
            availableSpace: 1024.0,
            receiptImages: 180.2,
            appData: 45.3,
            cache: 15.8,
            other: 4.4
        )
    }
    
    private func performCleanup(_ cleanupType: CleanupType) {
        isCleaningUp = true
        cleanupProgress = 0.0
        
        // Simulate cleanup process
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            cleanupProgress += 0.02
            if cleanupProgress >= 1.0 {
                timer.invalidate()
                isCleaningUp = false
                cleanupProgress = 0.0
                
                // Update storage data after cleanup
                loadStorageData()
            }
        }
    }
}

// MARK: - Supporting Views

struct StorageStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(AppTheme.cornerRadius)
    }
}

struct StorageBreakdownRow: View {
    let title: String
    let size: Double
    let percentage: Double
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                
                Text("\(String(format: "%.1f", size)) MB")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(String(format: "%.1f", percentage))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct StorageTipRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: AppTheme.spacing) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.primary)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct CleanupOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    let onCleanup: (CleanupType) -> Void
    
    var body: some View {
        NavigationStack {
            List {
                Section("Cleanup Options") {
                    CleanupOptionRow(
                        title: "Clear Cache",
                        description: "Remove temporary files and cache data",
                        size: "15.8 MB",
                        icon: "clock.fill",
                        color: Color(red: 230/255, green: 154/255, blue: 100/255)
                    ) {
                        onCleanup(.cache)
                        dismiss()
                    }
                    
                    CleanupOptionRow(
                        title: "Remove Old Images",
                        description: "Delete images older than 1 year",
                        size: "45.2 MB",
                        icon: "photo.fill",
                        color: .blue
                    ) {
                        onCleanup(.oldImages)
                        dismiss()
                    }
                    
                    CleanupOptionRow(
                        title: "Clear App Data",
                        description: "Remove unused app data and logs",
                        size: "12.3 MB",
                        icon: "doc.fill",
                        color: .green
                    ) {
                        onCleanup(.appData)
                        dismiss()
                    }
                    
                    CleanupOptionRow(
                        title: "Full Cleanup",
                        description: "Perform all cleanup operations",
                        size: "73.3 MB",
                        icon: "trash.fill",
                        color: .red
                    ) {
                        onCleanup(.full)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Cleanup Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CleanupOptionRow: View {
    let title: String
    let description: String
    let size: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(size)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Data Models

struct StorageData {
    let totalUsed: Double
    let availableSpace: Double
    let receiptImages: Double
    let appData: Double
    let cache: Double
    let other: Double
    
    var totalSpace: Double {
        totalUsed + availableSpace
    }
    
    var usagePercentage: Double {
        (totalUsed / totalSpace) * 100
    }
    
    var receiptImagesPercentage: Double {
        (receiptImages / totalUsed) * 100
    }
    
    var appDataPercentage: Double {
        (appData / totalUsed) * 100
    }
    
    var cachePercentage: Double {
        (cache / totalUsed) * 100
    }
    
    var otherPercentage: Double {
        (other / totalUsed) * 100
    }
}

enum CleanupType {
    case cache
    case oldImages
    case appData
    case full
}

#Preview {
    StorageUsageView()
}
