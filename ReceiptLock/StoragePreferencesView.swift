//
//  StoragePreferencesView.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI

struct StoragePreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("imageCompressionQuality") private var compressionQuality: Double = 0.8
    @AppStorage("maxImageSize") private var maxImageSize: Double = 2048
    @AppStorage("autoCompressImages") private var autoCompressImages: Bool = true
    @AppStorage("keepOriginalImages") private var keepOriginalImages: Bool = false
    @AppStorage("maxStorageLimit") private var maxStorageLimit: Double = 1024 // MB
    @AppStorage("cleanupOldImages") private var cleanupOldImages: Bool = true
    @AppStorage("imageRetentionDays") private var imageRetentionDays: Int = 365
    
    @State private var currentStorageUsage: Double = 0
    @State private var showingStorageCleanup = false
    
    private let sizeOptions = [
        (512.0, "512x512"),
        (1024.0, "1024x1024"),
        (2048.0, "2048x2048"),
        (4096.0, "4096x4096")
    ]
    
    private let retentionOptions = [
        (30, "30 days"),
        (90, "90 days"),
        (180, "180 days"),
        (365, "1 year"),
        (730, "2 years"),
        (1095, "3 years")
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Image Quality") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Compression Quality")
                            Spacer()
                            Text("\(Int(compressionQuality * 100))%")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $compressionQuality, in: 0.1...1.0, step: 0.1)
                            .accentColor(AppTheme.primary)
                    }
                    
                    HStack {
                        Text("Auto-compress Images")
                        Spacer()
                        Toggle("", isOn: $autoCompressImages)
                    }
                    
                    if autoCompressImages {
                        HStack {
                            Text("Max Image Size")
                            Spacer()
                            Picker("Max Size", selection: $maxImageSize) {
                                ForEach(sizeOptions, id: \.0) { size in
                                    Text(size.1).tag(size.0)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                    
                    HStack {
                        Text("Keep Original Images")
                        Spacer()
                        Toggle("", isOn: $keepOriginalImages)
                    }
                }
                
                Section("Storage Management") {
                    HStack {
                        Text("Current Usage")
                        Spacer()
                        Text("\(String(format: "%.1f", currentStorageUsage)) MB")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Storage Limit")
                        Spacer()
                        Picker("Storage Limit", selection: $maxStorageLimit) {
                            Text("512 MB").tag(512.0)
                            Text("1 GB").tag(1024.0)
                            Text("2 GB").tag(2048.0)
                            Text("5 GB").tag(5120.0)
                            Text("10 GB").tag(10240.0)
                        }
                        .pickerStyle(.menu)
                    }
                    
                    HStack {
                        Text("Auto-cleanup Old Images")
                        Spacer()
                        Toggle("", isOn: $cleanupOldImages)
                    }
                    
                    if cleanupOldImages {
                        HStack {
                            Text("Image Retention Period")
                            Spacer()
                            Picker("Retention", selection: $imageRetentionDays) {
                                ForEach(retentionOptions, id: \.0) { days in
                                    Text(days.1).tag(days.0)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                    
                    Button("Clean Up Storage") {
                        showingStorageCleanup = true
                    }
                    .foregroundColor(AppTheme.primary)
                }
                
                Section("Storage Information") {
                    StorageInfoRow(title: "Total Images", value: "1,247")
                    StorageInfoRow(title: "Compressed Images", value: "892")
                    StorageInfoRow(title: "Original Images", value: "355")
                    StorageInfoRow(title: "Available Space", value: "\(String(format: "%.1f", maxStorageLimit - currentStorageUsage)) MB")
                }
            }
            .navigationTitle("Storage Preferences")
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
            calculateStorageUsage()
        }
        .alert("Storage Cleanup", isPresented: $showingStorageCleanup) {
            Button("Clean Up", role: .destructive) {
                performStorageCleanup()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove old, unused images to free up storage space. This action cannot be undone.")
        }
    }
    
    private func calculateStorageUsage() {
        // Simulate storage calculation
        currentStorageUsage = 245.7
    }
    
    private func performStorageCleanup() {
        // Simulate cleanup process
        currentStorageUsage = max(0, currentStorageUsage - 50)
    }
}

struct StorageInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    StoragePreferencesView()
}
