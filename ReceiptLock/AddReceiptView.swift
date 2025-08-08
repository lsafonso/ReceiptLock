//
//  AddReceiptView.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI
import CoreData
import PhotosUI
import Vision
import VisionKit

struct AddReceiptView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var store = ""
    @State private var purchaseDate = Date()
    @State private var price = 0.0
    @State private var warrantyMonths = 12
    @State private var warrantySummary = ""
    @State private var selectedImage: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isProcessingOCR = false
    @State private var showingDocumentPicker = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Receipt Information") {
                    TextField("Title", text: $title)
                        .accessibilityLabel("Receipt title")
                    
                    TextField("Store", text: $store)
                        .accessibilityLabel("Store name")
                    
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                        .accessibilityLabel("Purchase date")
                    
                    HStack {
                        Text("Price")
                        Spacer()
                        TextField("0.00", value: $price, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Price amount")
                    }
                    
                    Stepper("Warranty: \(warrantyMonths) months", value: $warrantyMonths, in: 0...120)
                        .accessibilityLabel("Warranty duration in months")
                }
                
                Section("Receipt Image/PDF") {
                    if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .accessibilityLabel("Selected receipt image")
                    }
                    
                    HStack {
                        PhotosPicker(selection: $selectedImage, matching: .images) {
                            Label("Select Image", systemImage: "photo")
                        }
                        .accessibilityLabel("Select receipt image from photo library")
                        
                        Spacer()
                        
                        Button("Select PDF") {
                            showingDocumentPicker = true
                        }
                        .accessibilityLabel("Select receipt PDF document")
                    }
                    
                    if isProcessingOCR {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Processing OCR...")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if !warrantySummary.isEmpty {
                    Section("Warranty Summary") {
                        Text(warrantySummary)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Add Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveReceipt()
                    }
                    .disabled(title.isEmpty || store.isEmpty)
                }
            }
            .onChange(of: selectedImage) { _ in
                Task {
                    await loadImage()
                }
            }
            .onChange(of: purchaseDate) { _ in
                updateExpiryDate()
            }
            .onChange(of: warrantyMonths) { _ in
                updateExpiryDate()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .fileImporter(
                isPresented: $showingDocumentPicker,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                handlePDFSelection(result: result)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadImage() async {
        guard let selectedImage = selectedImage else { return }
        
        do {
            if let data = try await selectedImage.loadTransferable(type: Data.self) {
                selectedImageData = data
                await processOCR()
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load image: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
    
    private func processOCR() async {
        guard let imageData = selectedImageData,
              let uiImage = UIImage(data: imageData) else { return }
        
        await MainActor.run {
            isProcessingOCR = true
        }
        
        do {
            let text = try await performOCR(on: uiImage)
            await MainActor.run {
                processOCRResults(text: text)
                isProcessingOCR = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "OCR processing failed: \(error.localizedDescription)"
                showingError = true
                isProcessingOCR = false
            }
        }
    }
    
    private func performOCR(on image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("OCR error: \(error)")
            }
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        
        guard let observations = request.results else {
            throw OCRError.noResults
        }
        
        return observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
    }
    
    private func processOCRResults(text: String) {
        // Simple OCR result processing - in a real app, this would be more sophisticated
        let lowercasedText = text.lowercased()
        
        // Try to extract price
        let pricePattern = #"\$(\d+\.?\d*)"#
        if let priceMatch = lowercasedText.range(of: pricePattern, options: .regularExpression),
           let priceValue = Double(String(text[priceMatch]).replacingOccurrences(of: "$", with: "")) {
            price = priceValue
        }
        
        // Try to extract store name (simple heuristic)
        let storeKeywords = ["store", "shop", "market", "retail", "outlet"]
        for keyword in storeKeywords {
            if lowercasedText.contains(keyword) {
                // Extract surrounding text as store name
                if let range = lowercasedText.range(of: keyword) {
                    let start = lowercasedText.index(range.lowerBound, offsetBy: -20, limitedBy: lowercasedText.startIndex) ?? lowercasedText.startIndex
                    let end = lowercasedText.index(range.upperBound, offsetBy: 20, limitedBy: lowercasedText.endIndex) ?? lowercasedText.endIndex
                    let storeText = String(text[start..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !storeText.isEmpty {
                        store = storeText
                        break
                    }
                }
            }
        }
        
        // Generate warranty summary
        warrantySummary = "OCR detected text: \(String(text.prefix(200)))..."
    }
    
    private func handlePDFSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            // PDF processing would be implemented here
            print("Selected PDF: \(url)")
        case .failure(let error):
            errorMessage = "Failed to select PDF: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func updateExpiryDate() {
        // This would be called when purchase date or warranty months change
        // The actual expiry date calculation would be done when saving
    }
    
    private func saveReceipt() {
        let receipt = Receipt(context: viewContext)
        receipt.id = UUID()
        receipt.title = title
        receipt.store = store
        receipt.purchaseDate = purchaseDate
        receipt.price = price
        receipt.warrantyMonths = Int16(warrantyMonths)
        receipt.warrantySummary = warrantySummary
        receipt.createdAt = Date()
        receipt.updatedAt = Date()
        
        // Calculate expiry date
        if warrantyMonths > 0 {
            receipt.expiryDate = Calendar.current.date(byAdding: .month, value: warrantyMonths, to: purchaseDate)
        }
        
        // Save image if exists
        if let imageData = selectedImageData {
            saveReceiptImage(data: imageData, receipt: receipt)
        }
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save receipt: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func saveReceiptImage(data: Data, receipt: Receipt) {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let receiptsPath = documentsPath.appendingPathComponent("receipts")
        
        // Create receipts directory if it doesn't exist
        try? FileManager.default.createDirectory(at: receiptsPath, withIntermediateDirectories: true)
        
        let fileName = "\(receipt.id?.uuidString ?? UUID().uuidString).jpg"
        let fileURL = receiptsPath.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            receipt.fileName = fileName
        } catch {
            print("Error saving image: \(error)")
        }
    }
}

enum OCRError: Error {
    case invalidImage
    case noResults
}

#Preview {
    AddReceiptView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 