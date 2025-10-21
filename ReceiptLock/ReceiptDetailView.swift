//
//  ReceiptDetailView.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI
import CoreData

struct ReceiptDetailView: View {
    let receipt: Receipt
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var imageStorageManager = ImageStorageManager.shared
    
    @State private var showingImageFullScreen = false
    @State private var showingEditReceipt = false
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Receipt Image Section
                if let imageData = receipt.imageData, let uiImage = UIImage(data: imageData) {
                    VStack(spacing: 12) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 4)
                            .onTapGesture {
                                showingImageFullScreen = true
                            }
                        
                        HStack {
                            Button("View Full Screen") {
                                showingImageFullScreen = true
                            }
                            .buttonStyle(.bordered)
                            
                            Spacer()
                            
                            Button("Share") {
                                showingShareSheet = true
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Receipt Information Section
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: "Receipt Information")
                    
                    VStack(spacing: 12) {
                        InfoRow(title: "Title", value: receipt.title ?? "N/A")
                        InfoRow(title: "Store", value: receipt.store ?? "N/A")
                        InfoRow(title: "Price", value: formatPrice(receipt.price))
                        InfoRow(title: "Purchase Date", value: formatDate(receipt.purchaseDate))
                        InfoRow(title: "Warranty", value: formatWarranty(receipt.warrantyMonths))
                        
                        if let expiryDate = receipt.expiryDate {
                            InfoRow(title: "Expiry Date", value: formatDate(expiryDate))
                        }
                        
                        if let warrantySummary = receipt.warrantySummary, !warrantySummary.isEmpty {
                            InfoRow(title: "Warranty Details", value: warrantySummary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // OCR Data Section (if available)
                if let ocrText = receipt.ocrText, !ocrText.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "OCR Extracted Data")
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Raw OCR Text")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(ocrText)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                }
                
                // Metadata Section
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: "Metadata")
                    
                    VStack(spacing: 12) {
                        InfoRow(title: "Created", value: formatDate(receipt.createdAt))
                        InfoRow(title: "Last Updated", value: formatDate(receipt.updatedAt))
                        InfoRow(title: "OCR Processed", value: receipt.ocrProcessed ? "Yes" : "No")
                        
                        if let fileName = receipt.fileName {
                            InfoRow(title: "Image File", value: fileName)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button("Edit Receipt") {
                        showingEditReceipt = true
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    
                    Button("Delete Receipt") {
                        showingDeleteAlert = true
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(AppTheme.error)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .navigationTitle("Receipt Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditReceipt = true
                }
            }
        }
        .sheet(isPresented: $showingImageFullScreen) {
            if let imageData = receipt.imageData, let uiImage = UIImage(data: imageData) {
                ImageFullScreenView(image: uiImage)
            }
        }
        .sheet(isPresented: $showingEditReceipt) {
            EditReceiptView(receipt: receipt)
        }
        .alert("Delete Receipt", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteReceipt()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this receipt? This action cannot be undone.")
        }
        .sheet(isPresented: $showingShareSheet) {
            if let imageData = receipt.imageData, let uiImage = UIImage(data: imageData) {
                ShareSheet(items: [uiImage])
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatPrice(_ price: Double) -> String {
        return CurrencyManager.shared.formatPrice(price)
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
    }
    
    private func formatWarranty(_ months: Int16) -> String {
        if months == 0 {
            return "No warranty"
        } else if months == 1 {
            return "1 month"
        } else if months == 12 {
            return "1 year"
        } else if months % 12 == 0 {
            return "\(months / 12) years"
        } else {
            return "\(months) months"
        }
    }
    
    private func deleteReceipt() {
        // Delete associated image file
        if let fileName = receipt.fileName {
            imageStorageManager.deleteReceiptImage(fileName: fileName)
        }
        
        // Delete from Core Data
        viewContext.delete(receipt)
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error deleting receipt: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct ImageFullScreenView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        let delta = value / lastScale
                                        lastScale = value
                                        scale = scale * delta
                                    }
                                    .onEnded { _ in
                                        lastScale = 1.0
                                    },
                                DragGesture()
                                    .onChanged { value in
                                        let delta = CGSize(
                                            width: value.translation.width - lastOffset.width,
                                            height: value.translation.height - lastOffset.height
                                        )
                                        lastOffset = value.translation
                                        offset = CGSize(
                                            width: offset.width + delta.width,
                                            height: offset.height + delta.height
                                        )
                                    }
                                    .onEnded { _ in
                                        lastOffset = .zero
                                    }
                            )
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                scale = 1.0
                                offset = .zero
                            }
                        }
                }
            }
            .navigationTitle("Receipt Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            scale = 1.0
                            offset = .zero
                        }
                    }
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        ReceiptDetailView(receipt: Receipt())
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 