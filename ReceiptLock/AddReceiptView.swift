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
import PDFKit

struct AddReceiptView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var validationManager = ValidationManager()
    
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
    @State private var showingCamera = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var ocrText = ""
    @State private var showingOCRResults = false
    @State private var ocrData: ReceiptData?
    @State private var showingImageEditor = false
    @State private var editedImage: UIImage?
    @State private var selectedPDFURL: URL?
    @State private var pdfMetadata: PDFMetadata?
    
    // Initialize with a pre-selected image (from camera)
    init(selectedImage: UIImage? = nil) {
        if let image = selectedImage {
            _selectedImageData = State(initialValue: image.jpegData(compressionQuality: 0.8))
            _editedImage = State(initialValue: image)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                receiptInformationSection
                receiptImageSection
                documentSection
                ocrResultsSection
            }
            .navigationTitle("Add Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveReceipt()
                    }
                    .disabled(title.isEmpty || store.isEmpty)
                }
            }
            .sheet(isPresented: $showingImageEditor) {
                if let editedImage = editedImage {
                    ImageEditorView(image: editedImage) { editedImage in
                        self.editedImage = editedImage
                        if let imageData = editedImage?.jpegData(compressionQuality: 0.8) {
                            self.selectedImageData = imageData
                        }
                    }
                }
            }
            .sheet(isPresented: $showingOCRResults) {
                if let ocrData = ocrData {
                    VStack {
                        Text("OCR Results")
                            .font(.title)
                            .padding()
                        
                        Text("Extracted text: \(ocrData.rawText)")
                            .padding()
                        
                        Button("Apply Data") {
                            applyOCRData(ocrData)
                            showingOCRResults = false
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Receipt Information Section
    private var receiptInformationSection: some View {
        Section("Receipt Information") {
            ValidatedTextField(
                title: "Title",
                placeholder: "Enter receipt title",
                text: $title,
                fieldKey: "title",
                validationManager: validationManager,
                validationRule: validationManager.validateApplianceName
            )
            
            ValidatedTextField(
                title: "Store",
                placeholder: "Enter store name",
                text: $store,
                fieldKey: "store",
                validationManager: validationManager,
                validationRule: validationManager.validateStoreName
            )
            
            ValidatedDateField(
                title: "Purchase Date",
                date: $purchaseDate,
                fieldKey: "date",
                validationManager: validationManager
            )
            
            ValidatedPriceField(
                title: "Price",
                price: $price,
                fieldKey: "price",
                validationManager: validationManager
            )
            
            ValidatedStepperField(
                title: "Warranty",
                value: $warrantyMonths,
                range: 0...120,
                fieldKey: "warranty",
                validationManager: validationManager,
                validationRule: validationManager.validateWarrantyMonths
            )
        }
    }
    
    // MARK: - Receipt Image Section
    private var receiptImageSection: some View {
        Section("Receipt Image") {
            if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                VStack(spacing: 12) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .accessibilityLabel("Selected receipt image")
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .onTapGesture {
                            editedImage = uiImage
                            showingImageEditor = true
                        }
                    
                    HStack {
                        Button("Edit Image") {
                            editedImage = uiImage
                            showingImageEditor = true
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        Button("Process with OCR") {
                            Task {
                                await processImageWithOCR(uiImage)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isProcessingOCR)
                    }
                    
                    if isProcessingOCR {
                        VStack(spacing: 8) {
                            ProgressView(value: PDFService.shared.isProcessing ? PDFService.shared.processingProgress : OCRService.shared.processingProgress)
                                .progressViewStyle(LinearProgressViewStyle())
                                .scaleEffect(0.8)
                            
                            Text(PDFService.shared.isProcessing ? "Processing PDF..." : "Processing OCR...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                VStack(spacing: 16) {
                    HStack {
                        Button(action: { showingCamera = true }) {
                            Label("Take Photo", systemImage: "camera")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: { showingDocumentPicker = true }) {
                            Label("Choose Photo", systemImage: "photo.on.rectangle")
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Text("Select an image to get started")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
    }
    
    // MARK: - Document Section
    private var documentSection: some View {
        Section("Document Options") {
            HStack {
                Button(action: { showingCamera = true }) {
                    Label("Camera", systemImage: "camera")
                }
                .buttonStyle(.bordered)
                
                Button(action: { showingDocumentPicker = true }) {
                    Label("Photo Library", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    // MARK: - OCR Results Section
    private var ocrResultsSection: some View {
        Group {
            if !ocrText.isEmpty {
                Section("OCR Results") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Extracted Text:")
                            .font(.headline)
                        
                        Text(ocrText)
                            .font(.body)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions

    private func applyOCRData(_ ocrData: ReceiptData) {
        // Apply all available OCR data
        if let extractedTitle = ocrData.title, !extractedTitle.isEmpty {
            title = extractedTitle
        }
        
        if let extractedStore = ocrData.store, !extractedStore.isEmpty {
            store = extractedStore
        }
        
        if let extractedPrice = ocrData.price, extractedPrice > 0 {
            price = extractedPrice
        }
        
        if let extractedDate = ocrData.purchaseDate {
            purchaseDate = extractedDate
        }
        
        if let extractedWarranty = ocrData.warrantyInfo, !extractedWarranty.isEmpty {
            warrantySummary = extractedWarranty
        }
        
        // Update OCR text
        ocrText = ocrData.rawText
    }

    private func processImageWithOCR(_ image: UIImage) async {
        isProcessingOCR = true
        
        do {
            let ocrResult = try await OCRService.shared.processReceiptImage(image)
            await MainActor.run {
                ocrData = ocrResult
                ocrText = ocrResult.rawText
                showingOCRResults = true
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
    
    private func handlePDFSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            selectedPDFURL = url
            
            // Get PDF metadata
            if let metadata = PDFService.shared.getPDFMetadata(at: url) {
                pdfMetadata = metadata
            }
            
            Task {
                await processPDFWithOCR(url: url)
            }
        case .failure(let error):
            errorMessage = "Failed to select PDF: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func processPDFWithOCR(url: URL) async {
        await MainActor.run {
            isProcessingOCR = true
        }
        
        do {
            let pdfResult = try await PDFService.shared.processPDFWithOCR(at: url)
            
            await MainActor.run {
                if pdfResult.success {
                    ocrText = pdfResult.extractedText
                    
                    // Extract receipt data from PDF text
                    Task {
                        let receiptData = try await OCRService.shared.processReceiptImage(pdfResult.extractedImages.first ?? UIImage())
                        await MainActor.run {
                            ocrData = receiptData
                            
                            // Auto-fill fields if they're empty
                            if title.isEmpty, let extractedTitle = receiptData.title { title = extractedTitle }
                            if store.isEmpty, let extractedStore = receiptData.store { store = extractedStore }
                            if price == 0.0, let extractedPrice = receiptData.price { price = extractedPrice }
                            if let extractedDate = receiptData.purchaseDate { purchaseDate = extractedDate }
                            if let extractedWarranty = receiptData.warrantyInfo { warrantySummary = extractedWarranty }
                            
                            isProcessingOCR = false
                            showingOCRResults = true
                            validationManager.clearErrors()
                        }
                    }
                } else {
                    isProcessingOCR = false
                    errorMessage = "Failed to process PDF"
                    showingError = true
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "PDF processing failed: \(error.localizedDescription)"
                showingError = true
                isProcessingOCR = false
            }
        }
    }
    
    private func updateExpiryDate() {
        // This would be called when purchase date or warranty months change
        // The actual expiry date calculation would be done when saving
    }
    
    private func saveReceipt() {
        guard !title.isEmpty && !store.isEmpty else {
            errorMessage = "Please fill in all required fields"
            showingError = true
            return
        }
        
        let receipt = Receipt(context: viewContext)
        receipt.id = UUID()
        receipt.title = title
        receipt.store = store
        receipt.purchaseDate = purchaseDate
        receipt.price = price
        receipt.warrantyMonths = Int16(warrantyMonths)
        receipt.warrantySummary = warrantySummary
        receipt.createdAt = Date()
        
        if let imageData = selectedImageData {
            receipt.imageData = imageData
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
        if let uiImage = UIImage(data: data) {
            let fileName = ImageStorageManager.shared.saveReceiptImage(uiImage, for: receipt)
            receipt.fileName = fileName
        }
    }
}

// MARK: - OCR Result Row View

struct OCRResultRow: View {
    let title: String
    let value: String
    let isApplied: Bool
    let onApply: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            if isApplied {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppTheme.success)
                    .font(.title3)
            } else {
                Button("Apply") {
                    onApply()
                }
                .buttonStyle(.bordered)
                .scaleEffect(0.8)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Image Editor View

struct ImageEditorView: View {
    let image: UIImage
    let onSave: (UIImage?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var editedImage: UIImage
    @State private var brightness: Double = 0.0
    @State private var contrast: Double = 1.0
    @State private var saturation: Double = 0.0
    
    init(image: UIImage, onSave: @escaping (UIImage?) -> Void) {
        self.image = image
        self.onSave = onSave
        self._editedImage = State(initialValue: image)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Image(uiImage: editedImage)
                    .resizable()
                    .scaledToFit()
                    .padding()
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Brightness")
                            .font(.caption)
                        Slider(value: $brightness, in: -1.0...1.0) { _ in
                            applyFilters()
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Contrast")
                            .font(.caption)
                        Slider(value: $contrast, in: 0.5...2.0) { _ in
                            applyFilters()
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Saturation")
                            .font(.caption)
                        Slider(value: $saturation, in: 0.0...2.0) { _ in
                            applyFilters()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Edit Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(editedImage)
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func applyFilters() {
        guard let cgImage = image.cgImage else { return }
        
        let ciImage = CIImage(cgImage: cgImage)
        
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(brightness, forKey: kCIInputBrightnessKey)
        filter?.setValue(contrast, forKey: kCIInputContrastKey)
        filter?.setValue(saturation, forKey: kCIInputSaturationKey)
        
        if let outputImage = filter?.outputImage {
            let context = CIContext()
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                editedImage = UIImage(cgImage: cgImage)
            }
        }
    }
}

#Preview {
    AddReceiptView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 