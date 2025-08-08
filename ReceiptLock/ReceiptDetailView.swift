//
//  ReceiptDetailView.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI
import CoreData
import PDFKit
import UIKit

struct ReceiptDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let receipt: Receipt
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false
    @State private var shareURL: URL?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Receipt Image/PDF
                if let fileName = receipt.fileName {
                    ReceiptImageView(fileName: fileName)
                        .frame(height: 300)
                        .cornerRadius(12)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .frame(height: 200)
                        .overlay(
                            VStack {
                                Image(systemName: "doc.text")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                Text("No receipt image")
                                    .foregroundColor(.secondary)
                            }
                        )
                }
                
                // Receipt Information
                VStack(alignment: .leading, spacing: 16) {
                    InfoRow(title: "Title", value: receipt.title ?? "Untitled Receipt")
                    InfoRow(title: "Store", value: receipt.store ?? "Unknown Store")
                    InfoRow(title: "Purchase Date", value: receipt.purchaseDate?.formatted(date: .long, time: .omitted) ?? "Unknown")
                    InfoRow(title: "Price", value: "$\(String(format: "%.2f", receipt.price))")
                    InfoRow(title: "Warranty", value: "\(receipt.warrantyMonths) months")
                    
                    if let expiryDate = receipt.expiryDate {
                        InfoRow(
                            title: "Expiry Date",
                            value: expiryDate.formatted(date: .long, time: .omitted),
                            valueColor: expiryStatusColor(for: expiryDate)
                        )
                        
                        // Expiry status
                        HStack {
                            Image(systemName: expiryStatusIcon(for: expiryDate))
                                .foregroundColor(expiryStatusColor(for: expiryDate))
                            Text(expiryStatusText(for: expiryDate))
                                .foregroundColor(expiryStatusColor(for: expiryDate))
                                .fontWeight(.medium)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(expiryStatusColor(for: expiryDate).opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    if let warrantySummary = receipt.warrantySummary, !warrantySummary.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Warranty Summary")
                                .font(.headline)
                            Text(warrantySummary)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
            }
            .padding()
        }
        .navigationTitle("Receipt Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Edit") {
                        showingEditSheet = true
                    }
                    
                    Button("Share as PDF") {
                        generateAndSharePDF()
                    }
                    
                    Button("Delete", role: .destructive) {
                        showingDeleteAlert = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditReceiptView(receipt: receipt)
        }
        .alert("Delete Receipt", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteReceipt()
            }
        } message: {
            Text("Are you sure you want to delete this receipt? This action cannot be undone.")
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = shareURL {
                ShareSheet(items: [url])
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func expiryStatusColor(for date: Date) -> Color {
        let now = Date()
        let daysUntilExpiry = Calendar.current.dateComponents([.day], from: now, to: date).day ?? 0
        
        if date < now {
            return .red
        } else if daysUntilExpiry <= 7 {
            return .orange
        } else if daysUntilExpiry <= 30 {
            return .yellow
        } else {
            return .green
        }
    }
    
    private func expiryStatusIcon(for date: Date) -> String {
        let now = Date()
        let daysUntilExpiry = Calendar.current.dateComponents([.day], from: now, to: date).day ?? 0
        
        if date < now {
            return "exclamationmark.triangle.fill"
        } else if daysUntilExpiry <= 7 {
            return "clock.fill"
        } else if daysUntilExpiry <= 30 {
            return "clock"
        } else {
            return "checkmark.circle.fill"
        }
    }
    
    private func expiryStatusText(for date: Date) -> String {
        let now = Date()
        let daysUntilExpiry = Calendar.current.dateComponents([.day], from: now, to: date).day ?? 0
        
        if date < now {
            return "Warranty Expired"
        } else if daysUntilExpiry == 0 {
            return "Expires Today"
        } else if daysUntilExpiry == 1 {
            return "Expires Tomorrow"
        } else if daysUntilExpiry <= 7 {
            return "Expires in \(daysUntilExpiry) days"
        } else if daysUntilExpiry <= 30 {
            return "Expires in \(daysUntilExpiry) days"
        } else {
            return "Warranty Active"
        }
    }
    
    private func deleteReceipt() {
        // Delete associated file if exists
        if let fileName = receipt.fileName {
            deleteReceiptFile(fileName: fileName)
        }
        
        viewContext.delete(receipt)
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error deleting receipt: \(error)")
        }
    }
    
    private func deleteReceiptFile(fileName: String) {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let receiptsPath = documentsPath.appendingPathComponent("receipts")
        let fileURL = receiptsPath.appendingPathComponent(fileName)
        
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            print("Error deleting file: \(error)")
        }
    }
    
    private func generateAndSharePDF() {
        // Generate PDF summary
        let pdfData = generatePDFSummary()
        
        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("receipt_summary.pdf")
        
        do {
            try pdfData.write(to: tempURL)
            shareURL = tempURL
            showingShareSheet = true
        } catch {
            print("Error creating PDF: \(error)")
        }
    }
    
    private func generatePDFSummary() -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "ReceiptLock",
            kCGPDFContextAuthor: "ReceiptLock App"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let headerFont = UIFont.boldSystemFont(ofSize: 16)
            let bodyFont = UIFont.systemFont(ofSize: 14)
            
            var yPosition: CGFloat = 50
            
            // Title
            let title = "Receipt Summary"
            title.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: [.font: titleFont])
            yPosition += 40
            
            // Receipt details
            let details = [
                "Title: \(receipt.title ?? "Untitled")",
                "Store: \(receipt.store ?? "Unknown")",
                "Purchase Date: \(receipt.purchaseDate?.formatted(date: .long, time: .omitted) ?? "Unknown")",
                "Price: $\(String(format: "%.2f", receipt.price))",
                "Warranty: \(receipt.warrantyMonths) months"
            ]
            
            for detail in details {
                detail.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: [.font: bodyFont])
                yPosition += 20
            }
            
            if let expiryDate = receipt.expiryDate {
                yPosition += 10
                let expiryText = "Expiry Date: \(expiryDate.formatted(date: .long, time: .omitted))"
                expiryText.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: [.font: bodyFont])
                yPosition += 20
            }
            
            if let warrantySummary = receipt.warrantySummary, !warrantySummary.isEmpty {
                yPosition += 20
                "Warranty Summary:".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: [.font: headerFont])
                yPosition += 20
                warrantySummary.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: [.font: bodyFont])
            }
        }
        
        return data
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.body)
                .foregroundColor(valueColor)
        }
    }
}

struct ReceiptImageView: View {
    let fileName: String
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .overlay(
                        VStack {
                            Image(systemName: "doc.text")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("Image not found")
                                .foregroundColor(.secondary)
                        }
                    )
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            isLoading = false
            return
        }
        
        let receiptsPath = documentsPath.appendingPathComponent("receipts")
        let fileURL = receiptsPath.appendingPathComponent(fileName)
        
        do {
            let imageData = try Data(contentsOf: fileURL)
            image = UIImage(data: imageData)
        } catch {
            print("Error loading image: \(error)")
        }
        
        isLoading = false
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let receipt = Receipt(context: context)
    receipt.id = UUID()
    receipt.title = "iPhone 15 Pro"
    receipt.store = "Apple Store"
    receipt.price = 999.99
    receipt.purchaseDate = Date()
    receipt.warrantyMonths = 12
    receipt.expiryDate = Calendar.current.date(byAdding: .month, value: 12, to: Date())
    
    return NavigationStack {
        ReceiptDetailView(receipt: receipt)
    }
    .environment(\.managedObjectContext, context)
} 