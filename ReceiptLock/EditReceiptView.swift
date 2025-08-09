//
//  EditReceiptView.swift
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

struct EditReceiptView: View {
    let receipt: Receipt
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var validationManager = ValidationManager()
    
    @State private var title: String
    @State private var store: String
    @State private var purchaseDate: Date
    @State private var price: Double
    @State private var warrantyMonths: Int
    @State private var warrantySummary: String
    @State private var selectedImage: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isProcessingOCR = false
    @State private var showingDocumentPicker = false
    @State private var showingCamera = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var ocrText: String
    @State private var showingOCRResults = false
    @State private var ocrData: ReceiptData?
    @State private var showingImageEditor = false
    @State private var editedImage: UIImage?
    @State private var hasChanges = false
    @State private var selectedPDFURL: URL?
    @State private var pdfMetadata: PDFMetadata?
    
    // Initialize with existing receipt data
    init(receipt: Receipt) {
        self.receipt = receipt
        self._title = State(initialValue: receipt.title ?? "")
        self._store = State(initialValue: receipt.store ?? "")
        self._purchaseDate = State(initialValue: receipt.purchaseDate ?? Date())
        self._price = State(initialValue: receipt.price)
        self._warrantyMonths = State(initialValue: Int(receipt.warrantyMonths))
        self._warrantySummary = State(initialValue: receipt.warrantySummary ?? "")
        self._ocrText = State(initialValue: receipt.ocrText ?? "")
        
        // Initialize image data if exists
        if let imageData = receipt.imageData {
            self._selectedImageData = State(initialValue: imageData)
            if let uiImage = UIImage(data: imageData) {
                self._editedImage = State(initialValue: uiImage)
            }
        }
        
        // Initialize PDF data if exists
        if let pdfURLString = receipt.pdfURL, let pdfURL = URL(string: pdfURLString) {
            self._selectedPDFURL = State(initialValue: pdfURL)
            if receipt.pdfPageCount > 0 {
                let metadata = PDFMetadata(
                    pageCount: Int(receipt.pdfPageCount),
                    title: nil,
                    author: nil,
                    subject: nil,
                    creator: nil,
                    creationDate: nil,
                    modificationDate: nil
                )
                self._pdfMetadata = State(initialValue: metadata)
            }
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
            .navigationTitle("Edit Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!hasChanges)
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
            .onChange(of: title) { _, _ in
                checkForChanges()
            }
            
            ValidatedTextField(
                title: "Store",
                placeholder: "Enter store name",
                text: $store,
                fieldKey: "store",
                validationManager: validationManager,
                validationRule: validationManager.validateStoreName
            )
            .onChange(of: store) { _, _ in
                checkForChanges()
            }
            
            ValidatedDateField(
                title: "Purchase Date",
                date: $purchaseDate,
                fieldKey: "date",
                validationManager: validationManager
            )
            .onChange(of: purchaseDate) { _, _ in
                checkForChanges()
            }
            
            ValidatedPriceField(
                title: "Price",
                price: $price,
                fieldKey: "price",
                validationManager: validationManager
            )
            .onChange(of: price) { _, _ in
                checkForChanges()
            }
            
            ValidatedStepperField(
                title: "Warranty",
                value: $warrantyMonths,
                range: 0...120,
                fieldKey: "warranty",
                validationManager: validationManager,
                validationRule: validationManager.validateWarrantyMonths
            )
            .onChange(of: warrantyMonths) { _, _ in
                checkForChanges()
            }
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
                        .accessibilityLabel("Receipt image")
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
                            Label("Camera", systemImage: "camera")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: { showingDocumentPicker = true }) {
                            Label("Photo Library", systemImage: "photo.on.rectangle")
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
    
    // MARK: - Helper Methods
    
    private func loadImage() async {
        guard let selectedImage = selectedImage else { return }
        
        do {
            if let data = try await selectedImage.loadTransferable(type: Data.self) {
                selectedImageData = data
                if let uiImage = UIImage(data: data) {
                    editedImage = uiImage
                }
                checkForChanges()
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load image: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
    
    private func checkForChanges() {
        let originalTitle = receipt.title ?? ""
        let originalStore = receipt.store ?? ""
        let originalPrice = receipt.price
        let originalWarrantyMonths = Int(receipt.warrantyMonths)
        let originalWarrantySummary = receipt.warrantySummary ?? ""
        let originalPurchaseDate = receipt.purchaseDate ?? Date()
        
        let originalPDFURL = receipt.pdfURL
        let currentPDFURL = selectedPDFURL?.absoluteString
        
        hasChanges = title != originalTitle ||
                   store != originalStore ||
                   price != originalPrice ||
                   warrantyMonths != originalWarrantyMonths ||
                   warrantySummary != originalWarrantySummary ||
                   !Calendar.current.isDate(purchaseDate, inSameDayAs: originalPurchaseDate) ||
                   selectedImageData != receipt.imageData ||
                   currentPDFURL != originalPDFURL
    }
    
    private func validateForm() -> Bool {
        return validationManager.validateApplianceForm(
            title: title,
            store: store,
            price: price,
            warrantyMonths: warrantyMonths,
            purchaseDate: purchaseDate
        )
    }
    
    private func processImageWithOCR(_ image: UIImage) async {
        await MainActor.run {
            isProcessingOCR = true
        }
        
        do {
            let receiptData = try await OCRService.shared.processReceiptImage(image)
            
            await MainActor.run {
                // Store OCR results
                ocrText = receiptData.rawText
                ocrData = receiptData
                
                // Auto-fill fields if they're empty
                if title.isEmpty, let extractedTitle = receiptData.title {
                    title = extractedTitle
                }
                
                if store.isEmpty, let extractedStore = receiptData.store {
                    store = extractedStore
                }
                
                if price == 0.0, let extractedPrice = receiptData.price {
                    price = extractedPrice
                }
                
                if let extractedDate = receiptData.purchaseDate {
                    purchaseDate = extractedDate
                }
                
                if let extractedWarranty = receiptData.warrantyInfo {
                    warrantySummary = extractedWarranty
                }
                
                isProcessingOCR = false
                showingOCRResults = true
                
                // Clear validation errors after auto-filling
                validationManager.clearErrors()
                
                // Check for changes after OCR
                checkForChanges()
            }
        } catch {
            await MainActor.run {
                errorMessage = "OCR processing failed: \(error.localizedDescription)"
                showingError = true
                isProcessingOCR = false
            }
        }
    }
    
    private func applyAllOCRData() {
        guard let ocrData = ocrData else { return }
        
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
        
        showingOCRResults = false
        
        // Clear validation errors after applying
        validationManager.clearErrors()
        
        // Check for changes after applying OCR data
        checkForChanges()
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
                            
                            // Check for changes after applying OCR data
                            checkForChanges()
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
    
    private func updateReceipt() {
        // Update existing receipt
        receipt.title = title
        receipt.store = store
        receipt.purchaseDate = purchaseDate
        receipt.price = price
        receipt.warrantyMonths = Int16(warrantyMonths)
        receipt.warrantySummary = warrantySummary
        receipt.updatedAt = Date()
        receipt.ocrProcessed = !ocrText.isEmpty
        receipt.ocrText = ocrText
        
        // Calculate expiry date
        if warrantyMonths > 0 {
            receipt.expiryDate = Calendar.current.date(byAdding: .month, value: warrantyMonths, to: purchaseDate)
        } else {
            receipt.expiryDate = nil
        }
        
        // Update image if changed
        if let imageData = selectedImageData, imageData != receipt.imageData {
            receipt.imageData = imageData
            updateReceiptImage(data: imageData, receipt: receipt)
        }
        
        // Update PDF data if changed
        if let pdfURL = selectedPDFURL {
            receipt.pdfURL = pdfURL.absoluteString
            receipt.pdfPageCount = Int16(pdfMetadata?.pageCount ?? 0)
            receipt.pdfProcessed = true
        } else {
            receipt.pdfURL = nil
            receipt.pdfPageCount = 0
            receipt.pdfProcessed = false
        }
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to update receipt: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func updateReceiptImage(data: Data, receipt: Receipt) {
        if let uiImage = UIImage(data: data) {
            // Delete old image if exists
            if let oldFileName = receipt.fileName {
                ImageStorageManager.shared.deleteReceiptImage(fileName: oldFileName)
            }
            
            // Save new image
            let fileName = ImageStorageManager.shared.saveReceiptImage(uiImage, for: receipt)
            receipt.fileName = fileName
        }
    }
    
    private func saveChanges() {
        if validateForm() {
            updateReceipt()
        }
    }
    
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
        
        // Clear validation errors after applying
        validationManager.clearErrors()
        
        // Check for changes after applying OCR data
        checkForChanges()
    }
}

#Preview {
    EditReceiptView(receipt: Receipt())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 