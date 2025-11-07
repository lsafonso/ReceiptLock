//
//  AddApplianceView.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI
import CoreData
import PhotosUI
import Vision
import AVFoundation
import UIKit
import PDFKit
import UniformTypeIdentifiers
import CryptoKit
import VisionKit

struct AddApplianceView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var store = ""
    @State private var purchaseDate = Date()
    @State private var price: Double = 0.0
    @State private var warrantyMonths: Int = 12
    @State private var selectedImage: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var isProcessingOCR = false
    @State private var selectedDeviceType: DeviceType?
    @StateObject private var validationManager = ValidationManager()
    @State private var showingValidationAlert = false
    @State private var model = ""
    @State private var serialNumber = ""
    @State private var warrantySummary = ""
    @State private var notes = ""
    @State private var isSaving = false
    @State private var saveButtonState: SaveButtonState = .idle
    @State private var showingCodeScanner = false
    @State private var scannedCode: String?
    @State private var showingScannedCodeAlert = false
    @State private var savedApplianceID: UUID?
    @State private var navigateToDetail = false
    @State private var navigationPath = NavigationPath()
    @State private var isResetting = false
    @State private var showScanMenu = false
    @State private var showingReceiptCamera = false
    @State private var showingPhotoPicker = false
    @State private var showingCameraPermissionDenied = false
    @State private var showingDocumentScanner = false
    @State private var ocrError: String?
    @State private var showingOCRError = false
    @State private var selectedPDFURL: URL?
    @State private var pdfPageCount: Int = 0
    @State private var currentPDFPageIndex: Int = 0
    @State private var showingFileImporter = false
    @State private var detectedLines: [DetectedLine] = []
    @State private var processedPageHashes: Set<String> = []
    @State private var showingDetectedItems = false
    @State private var showingBatchEdit = false
    @State private var editableItems: [EditableItem] = []
    @State private var showingBatchCreationSuccess = false
    @State private var batchCreationCount = 0
    
    struct DetectedLine: Identifiable {
        let id = UUID()
        var text: String
        var amount: Decimal?
        var quantity: Int = 1
        var score: Double = 0.0 // Hidden score for filtering
    }
    
    // MARK: - Smart Line Detection
    
    struct DetectedCandidate: Identifiable {
        let id = UUID()
        var text: String
        var amount: Decimal?
        var quantity: Int?
        var bbox: CGRect? // Optional bounding box
        var score: Double
        var reasons: [String]
    }
    
    enum DeviceType: String, CaseIterable {
        case airConditioner = "Air Conditioner"
        case airCooler = "Air Cooler"
        case airFryer = "Air Fryer"
        case airPurifier = "Air Purifier"
        case audioSystem = "Audio System"
        case camera = "Camera"
        case desktop = "Desktop"
        case dishwasher = "Dishwasher"
        case fan = "Fan"
        case geyser = "Geyser"
        case headphone = "Headphone"
        case hobChimney = "Hob | Chimney"
        case juicerMixerGrinder = "Juicer | Mixer | Grinder"
        case laptop = "Laptop"
        case microwave = "Microwave"
        case mobile = "Mobile"
        case monitor = "Monitor"
        case printer = "Printer"
        case refrigerator = "Refrigerator"
        case smartwatch = "Smartwatch"
        case speaker = "Speaker"
        case tablet = "Tablet"
        case television = "Television"
        case washingMachine = "Washing Machine"
        
        var icon: String {
            switch self {
            case .airConditioner: return "snowflake"
            case .airCooler: return "wind"
            case .airFryer: return "flame"
            case .airPurifier: return "leaf"
            case .audioSystem: return "speaker.wave.3"
            case .camera: return "camera"
            case .desktop: return "desktopcomputer"
            case .dishwasher: return "drop"
            case .fan: return "fan"
            case .geyser: return "thermometer"
            case .headphone: return "headphones"
            case .hobChimney: return "flame.fill"
            case .juicerMixerGrinder: return "circle.hexagongrid"
            case .laptop: return "laptopcomputer"
            case .microwave: return "microwave"
            case .mobile: return "iphone"
            case .monitor: return "display"
            case .printer: return "printer"
            case .refrigerator: return "thermometer.snowflake"
            case .smartwatch: return "applewatch"
            case .speaker: return "speaker"
            case .tablet: return "ipad"
            case .television: return "tv"
            case .washingMachine: return "washer"
            }
        }
        
        var color: Color {
            switch self {
            case .airConditioner, .airCooler, .airPurifier: return .blue
            case .airFryer, .hobChimney: return AppTheme.primary
            case .audioSystem, .speaker, .headphone: return .purple
            case .camera: return .gray
            case .desktop, .laptop, .mobile, .tablet, .smartwatch: return .indigo
            case .dishwasher, .washingMachine: return .cyan
            case .fan: return .green
            case .geyser: return .red
            case .juicerMixerGrinder: return .pink
            case .microwave: return .brown
            case .monitor, .television: return .mint
            case .printer: return .black
            case .refrigerator: return .teal
            }
        }
    }
    
    // Computed property to check if user has started entering any data
    private var hasStartedEnteringData: Bool {
        !title.isEmpty ||
        !store.isEmpty ||
        !model.isEmpty ||
        !serialNumber.isEmpty ||
        price > 0 ||
        selectedDeviceType != nil ||
        selectedImage != nil ||
        scannedCode != nil
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Page Title at top left
                        Text("Add Appliance")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(AppTheme.text)
                            .padding(.horizontal, AppTheme.spacing)
                            .padding(.top, AppTheme.smallSpacing)
                        
                        // Scan receipt Section (only when enabled)
                        if FeatureFlags.isReceiptScanEnabled {
                            scanInvoiceSection
                                .padding(.horizontal, 24) // 24pt side insets for card alignment
                                .padding(.top, 24) // H1→intro block gap 24pt
                        }
                        
                        // Manual Entry Section
                        manualEntrySection
                            .padding(.horizontal, 24) // 24pt side insets for card alignment
                            .padding(.top, 24) // Block→grid gap 24pt
                        
                    }
                }
                .padding(.bottom, AppTheme.tabBarBottomPadding)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Only show Cancel and Save buttons when user has started entering data
                if hasStartedEnteringData {
                    ToolbarItem(placement: .navigationBarLeading) {
                        CancelButton(action: { 
                            resetForm()
                            dismiss() 
                        }, hasUnsavedChanges: hasStartedEnteringData)
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            saveAppliance()
                        } label: {
                            Text("Save")
                        }
                        .buttonStyle(PrimarySaveButtonStyle(state: saveButtonState))
                        .disabled(title.isEmpty || store.isEmpty || saveButtonState == .loading || isProcessingOCR)
                        .opacity((title.isEmpty || store.isEmpty || saveButtonState == .loading || isProcessingOCR) ? 0.4 : 1.0)
                    }
                }
            }
        }
        .onAppear {
            // Clear any lingering validation errors when view appears
            // This ensures clean state when navigating back from detail view
            if navigationPath.isEmpty {
                validationManager.clearErrors()
                
                // If we have a saved appliance ID but path is empty, 
                // user navigated back - reset the form
                if savedApplianceID != nil {
                    resetForm()
                    savedApplianceID = nil
                }
            }
        }
        .onChange(of: selectedImage) { oldValue, newValue in
            guard FeatureFlags.isReceiptScanEnabled, let newValue = newValue else { return }
            Task {
                await handlePhotoPickerSelection(item: newValue)
            }
        }
        .alert("Validation Errors", isPresented: $showingValidationAlert) {
            Button("OK") {
                validationManager.clearErrors()
            }
        } message: {
            Text("Please fix the validation errors before saving.")
        }
        .navigationDestination(for: UUID.self) { applianceID in
            Group {
                if let appliance = fetchAppliance(id: applianceID) {
                    ApplianceDetailView(appliance: appliance)
                }
            }
        }
        .onChange(of: navigateToDetail) { _, shouldNavigate in
            if shouldNavigate, let applianceID = savedApplianceID {
                navigationPath.append(applianceID)
                navigateToDetail = false
            }
        }
    }
    
    // MARK: - Scan Invoice Section
    private var scanInvoiceSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            Text("Scan or import")
                .rlHeadline()
            
            Text("Use your camera to scan a receipt or barcode, or import a photo or PDF. We'll auto-fill what we can.")
                .rlSubheadlineMuted()
            
            // Single primary button
            Button(action: {
                guard FeatureFlags.isReceiptScanEnabled else { return }
                print("[ScanMenu] open")
                showScanMenu = true
            }) {
                HStack(spacing: AppTheme.smallSpacing) {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                        .symbolRenderingMode(.monochrome)
                        .foregroundColor(.white)
                    
                    Text("Scan or Import")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.spacing)
                .background(AppTheme.primary)
                .cornerRadius(AppTheme.cornerRadius)
                .opacity(isProcessingOCR ? 0.6 : 1.0)
            }
            .disabled(isProcessingOCR || !FeatureFlags.isReceiptScanEnabled)
            .accessibilityLabel(FeatureFlags.isReceiptScanEnabled ? "Scan or import a receipt or barcode" : "Scan or Import, coming soon")
            .accessibilityHint(FeatureFlags.isReceiptScanEnabled ? "Opens options to scan with the camera or import from your library." : "This feature will be available in a future update.")
            .confirmationDialog("Scan or Import", isPresented: $showScanMenu, titleVisibility: .visible) {
                Button("Scan receipt (camera)") {
                    print("[ScanMenu] action: receipt")
                    presentReceiptCamera()
                }
                Button("Scan QR/Barcode") {
                    print("[ScanMenu] action: code")
                    presentCodeScanner()
                }
                Button("Import from Photos") {
                    print("[ScanMenu] action: import")
                    presentPhotoPicker()
                }
                Button("Import PDF") {
                    guard FeatureFlags.isReceiptScanEnabled else { return }
                    print("[ScanMenu] action: import-pdf")
                    showingFileImporter = true
                }
                Button("Cancel", role: .cancel) {
                    print("[ScanMenu] cancelled")
                }
            }
            
            // Show scanned code info if available
            if let code = scannedCode {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Scanned code: \(code)")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                    Spacer()
                    Button("Clear") {
                        scannedCode = nil
                    }
                    .font(.caption)
                    .foregroundColor(AppTheme.primary)
                }
                .padding(AppTheme.smallSpacing)
                .background(AppTheme.card)
                .cornerRadius(AppTheme.smallCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                        .stroke(AppTheme.separator, lineWidth: 1)
                )
            }
            
            if isProcessingOCR {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Processing receipt...")
                        .rlCaptionMuted()
                }
            }
        }
        .card() // Apply standard card styling
        .fullScreenCover(isPresented: $showingCodeScanner) {
            CodeScannerView(
                onScanned: { code in
                    handleScannedCode(code)
                },
                onCancel: {
                    // User cancelled - just dismiss
                }
            )
        }
        .alert("Code Scanned", isPresented: $showingScannedCodeAlert) {
            Button("Use as Serial Number") {
                if let code = scannedCode {
                    serialNumber = code
                }
                scannedCode = nil
            }
            Button("Use as Model") {
                if let code = scannedCode {
                    model = code
                }
                scannedCode = nil
            }
            Button("Cancel") {
                scannedCode = nil
            }
        } message: {
            if let code = scannedCode {
                Text("Scanned code: \(code)\n\nHow would you like to use this code?")
            }
        }
        .fullScreenCover(isPresented: $showingReceiptCamera) {
            CameraView(onCaptured: { image in
                print("[Scan] captured image")
                handleCapturedImage(image)
            })
        }
        .fullScreenCover(isPresented: $showingDocumentScanner) {
            DocumentScannerView { scan in
                print("[Scan] DocumentScanner completed with \(scan.pageCount) pages")
                // Use the first page of the scan
                if scan.pageCount > 0 {
                    let image = scan.imageOfPage(at: 0)
                    handleCapturedImage(image)
                }
            }
        }
        .photosPicker(
            isPresented: $showingPhotoPicker,
            selection: $selectedImage,
            matching: .images // Allow screenshots (e-receipts are often screenshots)
        )
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            handlePDFSelection(result: result)
        }
        .alert("Camera access needed", isPresented: $showingCameraPermissionDenied) {
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Import from Photos") {
                presentPhotoPicker()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Allow camera to scan receipts, or import a photo instead.")
        }
        .alert("Couldn't read this receipt", isPresented: $showingOCRError) {
            Button("OK") {
                ocrError = nil
            }
        } message: {
            Text("Couldn't read this receipt. You can fill details manually or try another photo.")
        }
        .sheet(isPresented: $showingDetectedItems) {
            VStack(spacing: 0) {
                // Multipage PDF banner
                if pdfPageCount > 1 {
                    HStack {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.blue)
                        Text("Didn't find all items? Try page \(currentPDFPageIndex + 2)")
                            .font(.caption)
                        Spacer()
                        if currentPDFPageIndex > 0 {
                            Button("Prev") {
                                Task {
                                    await processPreviousPDFPage()
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        if currentPDFPageIndex < pdfPageCount - 1 {
                            Button("Next") {
                                Task {
                                    await processNextPDFPage()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .onAppear {
                        print("[PDF] showing page navigation banner, page \(currentPDFPageIndex + 1)/\(pdfPageCount)")
                    }
                }
                
                DetectedReceiptItemsView(
                    lines: detectedLines,
                    onContinue: { selectedLines in
                        handleBatchCreation(selectedLines: selectedLines)
                    }
                )
            }
        }
        .sheet(isPresented: $showingBatchEdit) {
            BatchEditItemsSheet(
                items: editableItems,
                onCreate: { items in
                    createAppliancesFromEditableItems(items)
                }
            )
        }
        .alert("Items Created", isPresented: $showingBatchCreationSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Created \(batchCreationCount) items from the receipt")
        }
    }
    
    // MARK: - Scan Menu Actions
    
    private func presentReceiptCamera() {
        guard FeatureFlags.isReceiptScanEnabled else {
            print("[Scan] camera blocked - feature disabled")
            return
        }
        print("[Scan] camera presented")
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            // Try to start the camera session
            // If it fails, fallback to document scanner
            CameraService.shared.startSession()
            
            // Check if session started successfully after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if CameraService.shared.isSessionRunning {
                    self.showingReceiptCamera = true
                } else {
                    print("[Scan] fallback to DocumentScanner - session failed to start")
                    self.showingDocumentScanner = true
                }
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        CameraService.shared.startSession()
                        // Check if session started successfully
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if CameraService.shared.isSessionRunning {
                                self.showingReceiptCamera = true
                            } else {
                                print("[Scan] fallback to DocumentScanner - session failed after permission grant")
                                self.showingDocumentScanner = true
                            }
                        }
                    } else {
                        print("[Scan] fallback to DocumentScanner - permission denied")
                        self.showingDocumentScanner = true
                    }
                }
            }
        case .denied, .restricted:
            print("[Scan] fallback to DocumentScanner - permission denied/restricted")
            showingDocumentScanner = true
        @unknown default:
            print("[Scan] fallback to DocumentScanner - unknown authorization status")
            showingDocumentScanner = true
        }
    }
    
    private func presentCodeScanner() {
        guard FeatureFlags.isReceiptScanEnabled else {
            print("[Scan] code scanner blocked - feature disabled")
            return
        }
        // Check camera permission first
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            showingCodeScanner = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.showingCodeScanner = true
                    } else {
                        self.showingCameraPermissionDenied = true
                    }
                }
            }
        case .denied, .restricted:
            showingCameraPermissionDenied = true
        @unknown default:
            showingCameraPermissionDenied = true
        }
    }
    
    private func handleScannedCode(_ code: String) {
        print("[Code] scanned: \(code)")
        scannedCode = code
        showingScannedCodeAlert = true
    }
    
    private func presentPhotoPicker() {
        guard FeatureFlags.isReceiptScanEnabled else {
            print("[Scan] photo picker blocked - feature disabled")
            return
        }
        // Try PhotosPicker first (for images), and also show file importer option
        showingPhotoPicker = true
        // Note: User can also access PDFs via fileImporter if needed
        // For now, we'll handle PDFs through a separate flow if PhotosPicker doesn't support them
    }
    
    private func handlePDFSelection(result: Result<[URL], Error>) {
        guard FeatureFlags.isReceiptScanEnabled else {
            print("[Scan] PDF selection blocked - feature disabled")
            return
        }
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            selectedPDFURL = url
            Task {
                await handlePDFFile(url: url)
            }
        case .failure(let error):
            print("❌ [Import] PDF selection failed: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.isProcessingOCR = false
                self.ocrError = "Failed to load PDF"
                self.showingOCRError = true
            }
        }
    }
    
    private func handlePhotoPickerSelection(item: PhotosPickerItem) async {
        print("[Import] picked image/pdf")
        await MainActor.run {
            isProcessingOCR = true
        }
        
        // Try to load as image first (most common case)
        if let data = try? await item.loadTransferable(type: Data.self) {
            // Check if it's a PDF by checking the data header
            let pdfHeader = "%PDF"
            if data.count >= 4,
               let headerString = String(data: data.prefix(4), encoding: .ascii),
               headerString.hasPrefix(pdfHeader) {
                // It's a PDF - save to temp file and process
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".pdf")
                do {
                    try data.write(to: tempURL)
                    await handlePDFFile(url: tempURL)
                } catch {
                    print("❌ [Import] Failed to save PDF: \(error.localizedDescription)")
                    await MainActor.run {
                        self.isProcessingOCR = false
                        self.ocrError = "Failed to process PDF"
                        self.showingOCRError = true
                    }
                }
                return
            }
            
            // Try to load as UIImage
            if let uiImage = UIImage(data: data) {
                await MainActor.run {
                    if let imageData = uiImage.jpegData(compressionQuality: 0.9) {
                        self.imageData = imageData
                    }
                }
                print("[OCR] start")
                processImageWithOCR(uiImage)
            } else {
                // Failed to load as image
                await MainActor.run {
                    self.isProcessingOCR = false
                    self.ocrError = "Failed to load file"
                    self.showingOCRError = true
                }
            }
        } else {
            // Failed to load data
            await MainActor.run {
                self.isProcessingOCR = false
                self.ocrError = "Failed to load file"
                self.showingOCRError = true
            }
        }
    }
    
    private func handlePDFFile(url: URL) async {
        print("[Import] processing PDF")
        await MainActor.run {
            isProcessingOCR = true
        }
        
        do {
            // Get PDF page count
            guard let pdfDocument = PDFDocument(url: url) else {
                await MainActor.run {
                    self.isProcessingOCR = false
                    self.ocrError = "Invalid PDF document"
                    self.showingOCRError = true
                }
                return
            }
            
            let pageCount = pdfDocument.pageCount
            print("[PDF] page count: \(pageCount)")
            
            // Store the PDF URL and page info for reference
            await MainActor.run {
                self.selectedPDFURL = url
                self.pdfPageCount = pageCount
                self.currentPDFPageIndex = 0
                self.processedPageHashes = []
            }
            
            // Convert first page of PDF to image
            let images = try await PDFService.shared.convertPDFToImages(at: url, maxPages: 1)
            
            guard let firstPageImage = images.first else {
                await MainActor.run {
                    self.isProcessingOCR = false
                    self.ocrError = "PDF has no pages"
                    self.showingOCRError = true
                }
                return
            }
            
            await MainActor.run {
                if let imageData = firstPageImage.jpegData(compressionQuality: 0.9) {
                    self.imageData = imageData
                }
            }
            
            // Process the first page with OCR
            print("[OCR] start page 0")
            await processPDFPage(image: firstPageImage, pageIndex: 0)
            
        } catch {
            print("❌ [Import] PDF processing error: \(error.localizedDescription)")
            await MainActor.run {
                self.isProcessingOCR = false
                self.ocrError = "Failed to process PDF"
                self.showingOCRError = true
            }
        }
    }
    
    private func processPDFPage(image: UIImage, pageIndex: Int) async {
        print("[PDF] processing page \(pageIndex)")
        
        // Create hash of page text for deduplication
        let pageHash = image.pngData()?.base64EncodedString() ?? UUID().uuidString
        
        // Check if we've already processed this page
        if processedPageHashes.contains(pageHash) {
            print("[PDF] page \(pageIndex) already processed, skipping")
            return
        }
        
        await MainActor.run {
            processedPageHashes.insert(pageHash)
            currentPDFPageIndex = pageIndex
        }
        
        processImageWithOCR(image)
    }
    
    private func processNextPDFPage() async {
        guard let pdfURL = selectedPDFURL,
              currentPDFPageIndex < pdfPageCount - 1 else {
            return
        }
        
        let nextPageIndex = currentPDFPageIndex + 1
        
        await MainActor.run {
            isProcessingOCR = true
        }
        
        // Convert specific page to image
        guard let pdfDocument = PDFDocument(url: pdfURL),
              let page = pdfDocument.page(at: nextPageIndex) else {
            await MainActor.run {
                isProcessingOCR = false
            }
            return
        }
        
        let pageRect = page.bounds(for: .mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        
        let pageImage = renderer.image { context in
            UIColor.white.setFill()
            context.fill(pageRect)
            
            context.cgContext.translateBy(x: 0, y: pageRect.size.height)
            context.cgContext.scaleBy(x: 1.0, y: -1.0)
            
            page.draw(with: .mediaBox, to: context.cgContext)
        }
        
        await MainActor.run {
            if let imageData = pageImage.jpegData(compressionQuality: 0.9) {
                self.imageData = imageData
            }
        }
        
        print("[PDF] processing page \(nextPageIndex)")
        await processPDFPage(image: pageImage, pageIndex: nextPageIndex)
    }
    
    private func processPreviousPDFPage() async {
        guard let pdfURL = selectedPDFURL,
              currentPDFPageIndex > 0 else {
            return
        }
        
        let prevPageIndex = currentPDFPageIndex - 1
        
        await MainActor.run {
            isProcessingOCR = true
        }
        
        // Convert specific page to image
        guard let pdfDocument = PDFDocument(url: pdfURL),
              let page = pdfDocument.page(at: prevPageIndex) else {
            await MainActor.run {
                isProcessingOCR = false
            }
            return
        }
        
        let pageRect = page.bounds(for: .mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        
        let pageImage = renderer.image { context in
            UIColor.white.setFill()
            context.fill(pageRect)
            
            context.cgContext.translateBy(x: 0, y: pageRect.size.height)
            context.cgContext.scaleBy(x: 1.0, y: -1.0)
            
            page.draw(with: .mediaBox, to: context.cgContext)
        }
        
        await MainActor.run {
            if let imageData = pageImage.jpegData(compressionQuality: 0.9) {
                self.imageData = imageData
            }
        }
        
        print("[PDF] processing page \(prevPageIndex)")
        await processPDFPage(image: pageImage, pageIndex: prevPageIndex)
    }
    
    // MARK: - Image Processing
    
    private func downscale(_ img: UIImage, maxDimension: CGFloat = 2200) -> UIImage {
        let size = img.size
        let maxDim = max(size.width, size.height)
        
        // If image is already smaller than maxDimension, return as-is
        guard maxDim > maxDimension else { return img }
        
        // Calculate scale factor
        let scale = maxDimension / maxDim
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        // Use UIGraphicsImageRenderer for efficient downscaling
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            img.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    private func handleCapturedImage(_ image: UIImage) {
        // Downscale image before OCR to reduce memory and speed up Vision
        let downscaledImage = downscale(image, maxDimension: 2200)
        
        // Convert UIImage to Data
        guard let imageData = downscaledImage.jpegData(compressionQuality: 0.9) else {
            print("❌ [Scan] Failed to convert image to data")
            ocrError = "Failed to process image"
            showingOCRError = true
            return
        }
        
        // Store image data
        self.imageData = imageData
        
        // Process OCR
        print("[OCR] start")
        isProcessingOCR = true
        
        processImageWithOCR(downscaledImage)
    }
    
    private func processImageWithOCR(_ image: UIImage) {
        guard let cgImage = image.cgImage else {
            isProcessingOCR = false
            ocrError = "Invalid image"
            showingOCRError = true
            return
        }
        
        let request = VNRecognizeTextRequest { (request: VNRequest, error: Error?) -> Void in
            if let error = error {
                print("❌ [OCR] error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isProcessingOCR = false
                    self.ocrError = "OCR processing failed"
                    self.showingOCRError = true
                }
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                print("❌ [OCR] no text observations")
                DispatchQueue.main.async {
                    self.isProcessingOCR = false
                    self.ocrError = "No text found in image"
                    self.showingOCRError = true
                }
                return
            }
            
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            // Get image size for bounding box normalization
            var imageSize: CGSize? = nil
            if let cgImage = CameraService.shared.capturedImage?.cgImage {
                imageSize = CGSize(width: cgImage.width, height: cgImage.height)
            }
            
            // Process OCR results with bounding boxes
            DispatchQueue.main.async {
                self.processOCRResults(recognizedStrings, observations: observations, imageSize: imageSize)
                self.isProcessingOCR = false
                print("[OCR] done")
                // Clear captured image/preview buffers after successful OCR
                CameraService.shared.clearCapturedImage()
            }
        }
        
        request.recognitionLevel = VNRequestTextRecognitionLevel.accurate
        
        do {
            try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
        } catch {
            print("❌ [OCR] processing error: \(error.localizedDescription)")
            isProcessingOCR = false
            ocrError = "Couldn't read this receipt"
            showingOCRError = true
        }
    }
    
    // MARK: - Manual Entry Section
    private var manualEntrySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            Text("Select a device type to get started")
                .rlSubheadline()
            
            // Footnote when scan is disabled
            if !FeatureFlags.isReceiptScanEnabled {
                Text("Scanning isn't available yet.")
                    .font(.footnote)
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.leading)
                    .accessibilityLabel("Scanning isn't available yet.")
            }
            
            // Device Type Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) { // Card→card gap 12pt (both axes)
                ForEach(DeviceType.allCases, id: \.self) { deviceType in
                    Button(action: {
                        selectedDeviceType = deviceType
                        title = deviceType.rawValue
                        // Pre-fill model with device type as default
                        if model.isEmpty {
                            model = deviceType.rawValue
                        }
                    }) {
                        VStack(spacing: AppTheme.smallSpacing) {
                            Image(systemName: deviceType.icon)
                                .font(.title2)
                                .foregroundColor(deviceType.color)
                            
                            Text(deviceType.rawValue)
                                .rlCaption()
                                .fontWeight(.medium)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .frame(height: 80)
                        .frame(maxWidth: .infinity)
                        .padding(12) // Mini card padding 12pt
                        .background(AppTheme.card) // White card fill
                        .cornerRadius(AppTheme.CornerRadius.tile) // Mini card radius
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.tile)
                                .stroke(selectedDeviceType == deviceType ? deviceType.color : AppTheme.separator, lineWidth: 1)
                        )
                        .shadow(
                            color: .black.opacity(AppTheme.shadowOpacity),
                            radius: AppTheme.shadowRadius,
                            x: AppTheme.shadowOffset.width,
                            y: AppTheme.shadowOffset.height
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Form Fields
            formFields
        }
        .card() // Apply standard card styling
    }
    
    // MARK: - Form Fields
    private var formFields: some View {
        VStack(spacing: AppTheme.spacing) {
            // Basic Information Section
            VStack(alignment: .leading, spacing: AppTheme.spacing) {
                Text("Basic Information")
                    .rlHeadline()
                
                // Appliance Name Field
                ValidatedTextField(
                    title: "Appliance Name",
                    placeholder: "Enter appliance name",
                    text: $title,
                    fieldKey: "title",
                    validationManager: validationManager,
                    skipValidation: isResetting
                ) { value, fieldKey in
                    if isResetting { return true }
                    return validationManager.validateRequired(value, fieldName: "Appliance name", fieldKey: fieldKey) &&
                    validationManager.validateApplianceName(value, fieldKey: fieldKey)
                }
                
                // Store Field
                ValidatedTextField(
                    title: "Retailer / Store Name",
                    placeholder: "e.g., Amazon, IKEA, Currys",
                    text: $store,
                    fieldKey: "store",
                    validationManager: validationManager,
                    skipValidation: isResetting
                ) { value, fieldKey in
                    if isResetting { return true }
                    return validationManager.validateRequired(value, fieldName: "Store name", fieldKey: fieldKey) &&
                    validationManager.validateStoreName(value, fieldKey: fieldKey)
                }
                
                // Model Field
                ValidatedTextField(
                    title: "Model",
                    placeholder: "Enter model number",
                    text: $model,
                    fieldKey: "model",
                    validationManager: validationManager
                ) { value, fieldKey in
                    // Optional field - just clear any errors
                    validationManager.errors.removeValue(forKey: fieldKey)
                    return true
                }
                
                // Serial Number Field
                ValidatedTextField(
                    title: "Serial Number",
                    placeholder: "Enter serial number",
                    text: $serialNumber,
                    fieldKey: "serialNumber",
                    validationManager: validationManager
                ) { value, fieldKey in
                    // Optional field - just clear any errors
                    validationManager.errors.removeValue(forKey: fieldKey)
                    return true
                }
            }
            
            // Purchase Details Section
            VStack(alignment: .leading, spacing: AppTheme.spacing) {
                // Purchase Date Field
                ValidatedDateField(
                    title: "Purchase Date",
                    date: $purchaseDate,
                    fieldKey: "date",
                    validationManager: validationManager
                )
                
                // Price Field
                ValidatedPriceField(
                    title: "Price",
                    price: $price,
                    fieldKey: "price",
                    validationManager: validationManager
                )
            }
            
            // Warranty Section
            VStack(alignment: .leading, spacing: AppTheme.spacing) {
                // Warranty Duration Field
                ValidatedStepperField(
                    title: "Warranty Duration (months)",
                    value: $warrantyMonths,
                    range: 1...120,
                    fieldKey: "warranty",
                    validationManager: validationManager
                ) { value, fieldKey in
                    validationManager.validateWarrantyMonths(value, fieldKey: fieldKey)
                }
                
                // Warranty Summary Field
                ValidatedTextField(
                    title: "Warranty Summary",
                    placeholder: "Warranty Summary",
                    text: $warrantySummary,
                    fieldKey: "warrantySummary",
                    validationManager: validationManager
                ) { value, fieldKey in
                    // Optional field - just clear any errors
                    validationManager.errors.removeValue(forKey: fieldKey)
                    return true
                }
            }
            
            // Additional Notes Section
            VStack(alignment: .leading, spacing: AppTheme.spacing) {
                Text("Additional Notes")
                    .rlHeadline()
                
                // Notes Field
                ValidatedTextField(
                    title: "Notes",
                    placeholder: "Notes",
                    text: $notes,
                    fieldKey: "notes",
                    validationManager: validationManager
                ) { value, fieldKey in
                    // Optional field - just clear any errors
                    validationManager.errors.removeValue(forKey: fieldKey)
                    return true
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadImage() async {
        guard let selectedImage = selectedImage else { return }
        
        isProcessingOCR = true
        
        do {
            if let data = try await selectedImage.loadTransferable(type: Data.self) {
                imageData = data
                await processOCR()
            }
        } catch {
            print("Error loading image: \(error)")
        }
        
        isProcessingOCR = false
    }
    
    private func processOCR() async {
        guard let imageData = imageData,
              let uiImage = UIImage(data: imageData) else { return }
        
        let request = VNRecognizeTextRequest { (request: VNRequest, error: Error?) -> Void in
            if let error = error {
                print("OCR error: \(error)")
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            // Get image size for bounding box normalization
            var imageSize: CGSize? = nil
            if let cgImage = uiImage.cgImage {
                imageSize = CGSize(width: cgImage.width, height: cgImage.height)
            }
            
            // Process OCR results to extract appliance details
            DispatchQueue.main.async {
                self.processOCRResults(recognizedStrings, observations: observations, imageSize: imageSize)
            }
        }
        
        request.recognitionLevel = VNRequestTextRecognitionLevel.accurate
        
        do {
            try VNImageRequestHandler(cgImage: uiImage.cgImage!, options: [:]).perform([request])
        } catch {
            print("Error performing OCR: \(error)")
        }
    }
    
    private func processOCRResults(_ strings: [String], observations: [VNRecognizedTextObservation]? = nil, imageSize: CGSize? = nil) {
        // Combine all strings into raw OCR text
        let rawOCR = strings.joined(separator: "\n")
        
        // Parse into candidate lines with bounding boxes if available
        let candidateLines = parseDetectedLines(from: rawOCR, observations: observations, imageSize: imageSize)
        
        print("[MultiItem] candidates: \(candidateLines.count)")
        
        // Deduplicate by text hash
        var existingTextHashes = Set(detectedLines.map { $0.text.hashValue })
        let newLines = candidateLines.filter { line in
            let hash = line.text.hashValue
            if existingTextHashes.contains(hash) {
                print("[PDF] dedupe: skipping duplicate line '\(line.text.prefix(50))'")
                return false
            }
            existingTextHashes.insert(hash)
            return true
        }
        
        // Append new lines (for multi-page PDFs)
        if !newLines.isEmpty {
            detectedLines.append(contentsOf: newLines)
            print("[PDF] appended \(newLines.count) new lines, total: \(detectedLines.count)")
        }
        
        // If we detected multiple lines, show the selection UI
        if detectedLines.count > 1 {
            showingDetectedItems = true
            return
        }
        
        // Otherwise, fall back to single-item processing
        // Simple OCR processing - in a real app, you'd use more sophisticated parsing
        for string in strings {
            if string.lowercased().contains("air") && string.lowercased().contains("conditioner") {
                title = "Air Conditioner"
                selectedDeviceType = .airConditioner
                break
            } else if string.lowercased().contains("laptop") {
                title = "Laptop"
                selectedDeviceType = .laptop
                break
            } else if string.lowercased().contains("mobile") || string.lowercased().contains("phone") {
                title = "Mobile Phone"
                selectedDeviceType = .mobile
                break
            }
        }
        
        // Extract model information if found
        for string in strings {
            if string.lowercased().contains("model") || string.lowercased().contains("mod") {
                // Try to extract model number after "model" keyword
                let components = string.components(separatedBy: .whitespaces)
                if let modelIndex = components.firstIndex(where: { $0.lowercased().contains("model") || $0.lowercased().contains("mod") }),
                   modelIndex + 1 < components.count {
                    model = components[modelIndex + 1]
                    break
                }
            }
        }
        
        // Extract price if found
        for string in strings {
            if let priceValue = extractPrice(from: string) {
                price = priceValue
                break
            }
        }
    }
    
    private func parseDetectedLines(from rawOCR: String, observations: [VNRecognizedTextObservation]? = nil, imageSize: CGSize? = nil) -> [DetectedLine] {
        // Build candidates with scoring and bounding boxes
        let candidates = buildCandidatesFromOCRLines(rawOCR, observations: observations, imageSize: imageSize)
        
        // Apply region gating (drop header/footer)
        let gatedCandidates = applyRegionGating(candidates, imageSize: imageSize)
        
        // Merge two-line items (safer merge)
        let mergedCandidates = mergeTwoLineItems(gatedCandidates)
        
        // Extract receipt total from candidates (highest amount that looks like a total)
        let receiptTotal = extractReceiptTotal(from: mergedCandidates)
        
        // Filter: Keep candidates with score >= 1.0 as high confidence items
        // Also keep low confidence (0 <= score < 1.0) for "Show low confidence" toggle
        // Items with score < 0 are filtered out completely
        // Exclude duplicates of receipt total
        let filteredCandidates = mergedCandidates.filter { candidate in
            guard candidate.score >= 0.0 else { return false }
            
            // Exclude if amount equals receipt total within ±0.01
            if let candidateAmount = candidate.amount, let total = receiptTotal {
                let candidateDouble = NSDecimalNumber(decimal: candidateAmount).doubleValue
                let totalDouble = NSDecimalNumber(decimal: total).doubleValue
                if abs(candidateDouble - totalDouble) < 0.01 {
                    print("[OCR] drop duplicate-of-total: \(candidate.text) = \(candidateDouble)")
                    return false
                }
            }
            
            return true
        }
        
        // Sort by score (highest first)
        let sortedCandidates = filteredCandidates.sorted { $0.score > $1.score }
        
        // Cap to top 15 by score to avoid absurd cases
        let topCandidates = Array(sortedCandidates.prefix(15))
        
        // Convert to DetectedLine, preserving score
        let detectedLines = topCandidates.map { candidate in
            DetectedLine(
                text: candidate.text,
                amount: candidate.amount,
                quantity: candidate.quantity ?? 1,
                score: candidate.score
            )
        }
        
        print("[OCR] Total candidates: \(candidates.count), after gating: \(gatedCandidates.count), after merge: \(mergedCandidates.count), filtered (score>=0): \(filteredCandidates.count), top 15: \(detectedLines.count)")
        
        return detectedLines
    }
    
    // MARK: - Smart Detection Helpers
    
    private struct DetectionConstants {
        // Price regex: dynamically uses currency symbol
        static func priceRegex(currencySymbol: String) -> String {
            let escapedSymbol = NSRegularExpression.escapedPattern(for: currencySymbol)
            return "(?i)" + escapedSymbol + "?\\s*\\d{1,3}(?:,\\d{3})*(?:\\.\\d{2})|\\d+\\.\\d{2}"
        }
        
        // Quantity regexes
        static let qtyRegexes = [
            #"(?i)\bx\s*\d+\b"#,
            #"(?i)\b\d+\s*×\b"#,
            #"(?i)\bqty[:\s]*\d+\b"#,
            #"\(\s*\d+\s*\)"#,
            #"(?i)\b\d+\s*(?:pcs?|pc)\b"#
        ]
        
        // Stopwords (lowercased)
        static let stopwords: Set<String> = [
            "total", "sub total", "subtotal", "vat", "tax", "cash", "change",
            "card", "visa", "mastercard", "auth", "approval", "ref", "order",
            "transaction", "terminal", "merchant", "aid", "tvr", "tsi", "app",
            "date", "time", "tel", "phone", "vat no", "vat:", "www", "@"
        ]
        
        // Totals/payment regex (case-insensitive)
        static let totalsPaymentRegex = #"(?i)SUBTOTAL|SUB\s*TOTAL|TOTAL|BALANCE|AMOUNT\s*DUE|VAT|TAX|CASH|CHANGE|CARD|VISA|MASTERCARD|AUTH|APPROVAL|REF|TRANSACTION|TERMINAL|MERCHANT|AID|TVR|TSI"#
        
        // Address tokens
        static let addressTokens: Set<String> = [
            "road", "rd", "street", "st", "avenue", "ave", "lane", "ln",
            "belfast", "uk", "gb"
        ]
        
        // UK postcode regex
        static let ukPostcodeRegex = #"\b[A-Z]{1,2}\d{1,2}[A-Z]?\s*\d[A-Z]{2}\b"#
    }
    
    // MARK: - Price Normalization
    
    private func normalizePriceString(_ priceString: String, currencySymbol: String) -> Decimal? {
        // Strip currency symbols and spaces
        var normalized = priceString
            .replacingOccurrences(of: currencySymbol, with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if both '.' and ',' are present
        let hasDot = normalized.contains(".")
        let hasComma = normalized.contains(",")
        
        if hasDot && hasComma {
            // Treat the RIGHTMOST separator as decimal, remove the other
            let lastDotIndex = normalized.lastIndex(of: ".") ?? normalized.endIndex
            let lastCommaIndex = normalized.lastIndex(of: ",") ?? normalized.endIndex
            
            if lastDotIndex > lastCommaIndex {
                // Dot is rightmost, remove commas
                normalized = normalized.replacingOccurrences(of: ",", with: "")
            } else {
                // Comma is rightmost, replace with dot and remove other commas
                normalized = normalized.replacingOccurrences(of: ",", with: ".")
                normalized = normalized.replacingOccurrences(of: ".", with: "", options: [], range: normalized.startIndex..<normalized.index(before: normalized.endIndex))
                normalized = normalized + "."
            }
        } else if hasComma {
            // Only comma: if exactly 2 digits after last comma, replace with dot
            if let lastCommaIndex = normalized.lastIndex(of: ",") {
                let afterComma = String(normalized[normalized.index(after: lastCommaIndex)...])
                if afterComma.count == 2 && afterComma.allSatisfy({ $0.isNumber }) {
                    normalized = normalized.replacingOccurrences(of: ",", with: ".")
                } else {
                    // Remove comma (thousands separator)
                    normalized = normalized.replacingOccurrences(of: ",", with: "")
                }
            }
        } else if hasDot {
            // Only dot: if exactly 2 digits after last dot, keep it
            if let lastDotIndex = normalized.lastIndex(of: ".") {
                let afterDot = String(normalized[normalized.index(after: lastDotIndex)...])
                if afterDot.count != 2 {
                    // Not exactly 2 digits, might be thousands separator
                    normalized = normalized.replacingOccurrences(of: ".", with: "")
                }
            }
        }
        
        // Parse and validate range (0.30 to 5000)
        if let priceValue = Double(normalized) {
            if priceValue >= 0.30 && priceValue <= 5000 {
                return Decimal(priceValue)
            }
        }
        
        return nil
    }
    
    // MARK: - Receipt Total Extraction
    
    private func extractReceiptTotal(from candidates: [DetectedCandidate]) -> Decimal? {
        // Look for the highest amount that appears to be a total
        // Typically totals appear near the end and have words like "total", "balance", etc.
        var totalCandidates: [(amount: Decimal, score: Double, isTotal: Bool)] = []
        
        for candidate in candidates {
            guard let amount = candidate.amount else { continue }
            let lowercased = candidate.text.lowercased()
            
            // Check if it looks like a total line
            let isTotal = lowercased.contains("total") || 
                          lowercased.contains("balance") || 
                          lowercased.contains("amount due") ||
                          lowercased.contains("grand total")
            
            totalCandidates.append((amount: amount, score: candidate.score, isTotal: isTotal))
        }
        
        // Prefer candidates that explicitly say "total"
        if let explicitTotal = totalCandidates.first(where: { $0.isTotal }) {
            return explicitTotal.amount
        }
        
        // Otherwise, return the highest amount (likely the total)
        if let highest = totalCandidates.max(by: { $0.amount < $1.amount }) {
            return highest.amount
        }
        
        return nil
    }
    
    // MARK: - Region Gating
    
    private func applyRegionGating(_ candidates: [DetectedCandidate], imageSize: CGSize?) -> [DetectedCandidate] {
        guard let imageSize = imageSize, imageSize.height > 0 else {
            // No image size available, return all candidates
            return candidates
        }
        
        let maxY = imageSize.height
        var droppedCount = 0
        
        let gated = candidates.filter { candidate in
            guard let bbox = candidate.bbox else {
                // No bounding box, keep it (fallback to index-based if needed)
                return true
            }
            
            // Normalize Y coordinates (Vision uses bottom-left origin, so we need to flip)
            let normalizedMinY = 1.0 - (bbox.maxY / maxY)
            let normalizedMaxY = 1.0 - (bbox.minY / maxY)
            
            // Drop header (top 12%) or footer (bottom 18%)
            if normalizedMinY < 0.12 || normalizedMaxY > 0.82 {
                droppedCount += 1
                return false
            }
            
            return true
        }
        
        if droppedCount > 0 {
            print("[OCR] gated header/footer: dropped \(droppedCount)/\(candidates.count)")
        }
        
        return gated
    }
    
    private func buildCandidatesFromOCRLines(_ rawOCR: String, observations: [VNRecognizedTextObservation]? = nil, imageSize: CGSize? = nil) -> [DetectedCandidate] {
        // Split by line breaks
        let lines = rawOCR.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Create a mapping from text to bounding box if observations are available
        var textToBbox: [String: CGRect] = [:]
        if let observations = observations, let imageSize = imageSize {
            for observation in observations {
                if let text = observation.topCandidates(1).first?.string {
                    let bbox = observation.boundingBox
                    // Convert normalized coordinates to image coordinates
                    let imageBbox = CGRect(
                        x: bbox.origin.x * imageSize.width,
                        y: (1.0 - bbox.maxY) * imageSize.height, // Flip Y coordinate
                        width: bbox.width * imageSize.width,
                        height: bbox.height * imageSize.height
                    )
                    textToBbox[text] = imageBbox
                }
            }
        }
        
        var candidates: [DetectedCandidate] = []
        
        for line in lines {
            let lowercased = line.lowercased()
            
            // Check for price with robust UK/EU normalization
            var amount: Decimal? = nil
            var hasPrice = false
            let currencySymbol = CurrencyManager.shared.currencySymbol
            let pricePattern = DetectionConstants.priceRegex(currencySymbol: currencySymbol)
            if let priceRegex = try? NSRegularExpression(pattern: pricePattern) {
                let range = NSRange(location: 0, length: line.utf16.count)
                let matches = priceRegex.matches(in: line, range: range)
                if let lastMatch = matches.last {
                    let matchString = (line as NSString).substring(with: lastMatch.range)
                    // Robust price normalization
                    if let normalizedPrice = normalizePriceString(matchString, currencySymbol: currencySymbol) {
                        amount = normalizedPrice
                        hasPrice = true
                    }
                }
            }
            
            // Check for letters and digits
            let hasLetters = line.rangeOfCharacter(from: .letters) != nil
            let hasDigits = line.rangeOfCharacter(from: .decimalDigits) != nil
            let isNumericOnly = !hasLetters && !hasPrice
            
            // Check for stopwords (both set-based and regex-based)
            var isStop = false
            
            // Check set-based stopwords
            for stopword in DetectionConstants.stopwords {
                if lowercased.contains(stopword) {
                    isStop = true
                    print("[OCR] drop stopword '\(line)'")
                    break
                }
            }
            
            // Check totals/payment regex
            if !isStop, let totalsRegex = try? NSRegularExpression(pattern: DetectionConstants.totalsPaymentRegex) {
                let range = NSRange(location: 0, length: line.utf16.count)
                if totalsRegex.firstMatch(in: line, range: range) != nil {
                    isStop = true
                    print("[OCR] drop totals/payment '\(line)'")
                }
            }
            
            // Check for address tokens
            if !isStop {
                for token in DetectionConstants.addressTokens {
                    if lowercased.contains(token) {
                        isStop = true
                        break
                    }
                }
            }
            
            // Check for UK postcode
            if !isStop, let postcodeRegex = try? NSRegularExpression(pattern: DetectionConstants.ukPostcodeRegex) {
                let range = NSRange(location: 0, length: line.utf16.count)
                if postcodeRegex.firstMatch(in: line, range: range) != nil {
                    isStop = true
                }
            }
            
            // Extract quantity
            var quantity: Int? = nil
            var hasQty = false
            for qtyPattern in DetectionConstants.qtyRegexes {
                if let qtyRegex = try? NSRegularExpression(pattern: qtyPattern) {
                    let range = NSRange(location: 0, length: line.utf16.count)
                    if let match = qtyRegex.firstMatch(in: line, range: range) {
                        let matchString = (line as NSString).substring(with: match.range)
                        let cleanQty = matchString
                            .replacingOccurrences(of: "x", with: "", options: .caseInsensitive)
                            .replacingOccurrences(of: "×", with: "")
                            .replacingOccurrences(of: "qty", with: "", options: .caseInsensitive)
                            .replacingOccurrences(of: "quantity", with: "", options: .caseInsensitive)
                            .replacingOccurrences(of: "pcs", with: "", options: .caseInsensitive)
                            .replacingOccurrences(of: "pc", with: "", options: .caseInsensitive)
                            .replacingOccurrences(of: "(", with: "")
                            .replacingOccurrences(of: ")", with: "")
                            .replacingOccurrences(of: ":", with: "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        if let qty = Int(cleanQty), qty > 0 {
                            quantity = qty
                            hasQty = true
                            break
                        }
                    }
                }
            }
            
            // Compute score
            var score: Double = 0.0
            var reasons: [String] = []
            
            if hasPrice {
                score += 2.0
                reasons.append("hasPrice")
            }
            
            if hasLetters && hasDigits {
                score += 0.8
                reasons.append("hasLettersAndDigits")
            }
            
            if isStop {
                score -= 2.0
                reasons.append("isStopword")
            }
            
            if isNumericOnly {
                score -= 2.0
                reasons.append("isNumericOnly")
            }
            
            // Check amount range (0.30 to 5000) - updated threshold
            if let amt = amount {
                let amtDouble = NSDecimalNumber(decimal: amt).doubleValue
                if amtDouble < 0.30 || amtDouble > 5000 {
                    score -= 1.0
                    reasons.append("amountOutOfRange")
                }
            }
            
            if hasQty {
                score += 0.5
                reasons.append("hasQuantity")
            }
            
            // Get bounding box for this line
            let bbox = textToBbox[line]
            
            // Create candidate
            let candidate = DetectedCandidate(
                text: line,
                amount: amount,
                quantity: quantity,
                bbox: bbox,
                score: score,
                reasons: reasons
            )
            
            candidates.append(candidate)
            
            print("[OCR] cand score=\(String(format: "%.1f", score)) amt=\(amount != nil ? String(describing: amount!) : "nil") qty=\(quantity != nil ? String(quantity!) : "nil") text=\(line.prefix(50))")
        }
        
        return candidates
    }
    
    private func mergeTwoLineItems(_ candidates: [DetectedCandidate]) -> [DetectedCandidate] {
        guard candidates.count > 1 else { return candidates }
        
        var merged: [DetectedCandidate] = []
        var skipIndices: Set<Int> = []
        
        var i = 0
        while i < candidates.count {
            if skipIndices.contains(i) {
                i += 1
                continue
            }
            
            let current = candidates[i]
            
            // Check if we can merge with next line
            if i + 1 < candidates.count && !skipIndices.contains(i + 1) {
                let next = candidates[i + 1]
                
                // Check if next has price and score >= 1.0
                if next.amount != nil && next.score >= 1.0 {
                    // Safer merge conditions:
                    // 1. Current has at least 3 letters
                    // 2. Current has no price
                    // 3. Current is not a stopword
                    // 4. Current is not code-only (has letters, length >= 3)
                    let currentLower = current.text.lowercased()
                    let letterCount = current.text.filter { $0.isLetter }.count
                    let hasCurrentPrice = current.amount != nil
                    var isCurrentStop = false
                    
                    // Check stopwords
                    for stopword in DetectionConstants.stopwords {
                        if currentLower.contains(stopword) {
                            isCurrentStop = true
                            break
                        }
                    }
                    
                    // Check totals/payment regex
                    if !isCurrentStop, let totalsRegex = try? NSRegularExpression(pattern: DetectionConstants.totalsPaymentRegex) {
                        let range = NSRange(location: 0, length: current.text.utf16.count)
                        if totalsRegex.firstMatch(in: current.text, range: range) != nil {
                            isCurrentStop = true
                        }
                    }
                    
                    // Check gap (use index adjacency if bbox missing, or check vertical distance)
                    var gapIsSmall = true
                    if let currentBbox = current.bbox, let nextBbox = next.bbox {
                        // If both have bounding boxes, check vertical gap
                        let gap = abs(nextBbox.minY - currentBbox.maxY)
                        let avgHeight = (currentBbox.height + nextBbox.height) / 2
                        gapIsSmall = gap < avgHeight * 2 // Gap should be less than 2x average line height
                    } else {
                        // No bounding boxes, use index adjacency (adjacent indices are close)
                        gapIsSmall = true
                    }
                    
                    // Merge conditions: letterCount >= 3, no price, not stopword, gap is small
                    if letterCount >= 3 && !hasCurrentPrice && !isCurrentStop && gapIsSmall && current.text.count >= 3 {
                        // Merge: current + " — " + next
                        let mergedText = current.text + " — " + next.text
                        let mergedAmount = next.amount
                        let mergedQty = next.quantity ?? current.quantity
                        let mergedScore = next.score + 0.7
                        var mergedReasons = next.reasons
                        mergedReasons.append("merged")
                        
                        let mergedCandidate = DetectedCandidate(
                            text: mergedText,
                            amount: mergedAmount,
                            quantity: mergedQty,
                            bbox: next.bbox ?? current.bbox, // Use next's bbox if available
                            score: mergedScore,
                            reasons: mergedReasons
                        )
                        
                        merged.append(mergedCandidate)
                        skipIndices.insert(i)
                        skipIndices.insert(i + 1)
                        
                        print("[OCR] merge prev+current -> '\(mergedText.prefix(80))'")
                        i += 2
                        continue
                    }
                }
            }
            
            // If not merged, add current
            merged.append(current)
            i += 1
        }
        
        return merged
    }
    
    private func handleBatchCreation(selectedLines: [DetectedLine]) {
        print("[MultiItem] selected: \(selectedLines.count)")
        
        guard !selectedLines.isEmpty else { return }
        
        // Convert DetectedLines to EditableItems for batch editing
        editableItems = selectedLines.map { line in
            EditableItem(
                id: line.id,
                title: line.text,
                price: line.amount,
                warrantyMonths: 12,
                category: "",
                originalLineText: line.text,
                quantity: line.quantity
            )
        }
        
        // Show batch edit sheet
        showingBatchEdit = true
    }
    
    private func createAppliancesFromEditableItems(_ items: [EditableItem]) {
        guard !items.isEmpty else { return }
        
        var createdCount = 0
        var createdReceiptItemIds = Set<UUID>() // Guard against double-creation
        
        // Calculate total price for receipt
        var totalPrice: Double = 0.0
        for item in items {
            if let amount = item.price {
                totalPrice += NSDecimalNumber(decimal: amount).doubleValue * Double(item.quantity)
            }
        }
        
        // Create or reuse receipt (ONE receipt for all appliances)
        var receipt: Receipt?
        if let imageData = imageData {
            receipt = findOrCreateReceipt(
                imageData: imageData,
                store: store,
                purchaseDate: purchaseDate,
                totalPrice: totalPrice
            )
        }
        
        // Create all appliances and receipt items
        for item in items {
            // Skip if title is empty
            guard !item.title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty else { continue }
            
            // Create appliance for each quantity
            for _ in 0..<item.quantity {
                let appliance = NSEntityDescription.insertNewObject(forEntityName: "Appliance", into: viewContext) as! Appliance
                appliance.id = UUID()
                
                // Use item title
                appliance.name = item.title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                
                // Copy store, purchaseDate from current state
                appliance.brand = store.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                appliance.purchaseDate = purchaseDate
                
                // Set price if available
                if let amount = item.price {
                    appliance.price = NSDecimalNumber(decimal: amount).doubleValue
                } else {
                    appliance.price = 0.0
                }
                
                // Set warranty months
                appliance.warrantyMonths = Int16(item.warrantyMonths)
                
                // Set category/device type if selected
                if !item.category.isEmpty,
                   let deviceType = DeviceType.allCases.first(where: { $0.rawValue == item.category }) {
                    // Store device type info in model field if model is empty
                    if model.isEmpty {
                        appliance.model = deviceType.rawValue
                    }
                }
                
                appliance.createdAt = Date()
                
                // Calculate expiry date
                if let expiryDate = Calendar.current.date(byAdding: .month, value: item.warrantyMonths, to: purchaseDate) {
                    appliance.warrantyExpiryDate = expiryDate
                }
                
                // Create ReceiptItem to link receipt and appliance
                if let receipt = receipt {
                    let receiptItem = ReceiptItem(context: viewContext)
                    receiptItem.id = UUID()
                    receiptItem.receipt = receipt
                    receiptItem.appliance = appliance
                    receiptItem.originalLineText = item.originalLineText
                    receiptItem.quantity = Int16(item.quantity)
                    
                    if let amount = item.price {
                        receiptItem.lineAmount = NSDecimalNumber(decimal: amount)
                    }
                    
                    // Safety check: prevent double-creation
                    if let itemId = receiptItem.id, !createdReceiptItemIds.contains(itemId) {
                        createdReceiptItemIds.insert(itemId)
                    }
                }
                
                createdCount += 1
            }
        }
        
        // Save context
        do {
            try viewContext.save()
            batchCreationCount = createdCount
            showingBatchEdit = false
            showingBatchCreationSuccess = true
        } catch {
            print("❌ Error creating batch appliances: \(error)")
            ocrError = "Failed to create items"
            showingOCRError = true
        }
    }
    
    private func findOrCreateReceipt(imageData: Data, store: String, purchaseDate: Date, totalPrice: Double) -> Receipt? {
        // Compute SHA-256 hash of image
        let imageHash = SHA256.hash(data: imageData)
        let imageHashString = imageHash.compactMap { String(format: "%02x", $0) }.joined()
        
        // Check for existing receipt with same image hash (using imageHash attribute)
        let fetchRequest = NSFetchRequest<Receipt>(entityName: "Receipt")
        fetchRequest.predicate = NSPredicate(format: "imageHash == %@", imageHashString)
        fetchRequest.fetchLimit = 1
        
        do {
            if let existingReceipt = try viewContext.fetch(fetchRequest).first {
                print("[MultiItem] using receiptId: \(existingReceipt.id?.uuidString ?? "unknown") (reused)")
                return existingReceipt
            }
        } catch {
            print("❌ Error fetching existing receipts: \(error)")
        }
        
        // Also check by date and price as fallback (for receipts without imageHash set)
        let calendar = Calendar.current
        let dayBefore = calendar.date(byAdding: .day, value: -1, to: purchaseDate)!
        let dayAfter = calendar.date(byAdding: .day, value: 1, to: purchaseDate)!
        let priceTolerance = 0.01
        
        let fallbackFetch = NSFetchRequest<Receipt>(entityName: "Receipt")
        fallbackFetch.predicate = NSPredicate(format: "purchaseDate >= %@ AND purchaseDate <= %@ AND price >= %f AND price <= %f AND (imageHash == nil OR imageHash == '')", 
                                             dayBefore as NSDate, dayAfter as NSDate, 
                                             totalPrice - priceTolerance, totalPrice + priceTolerance)
        
        do {
            let existingReceipts = try viewContext.fetch(fallbackFetch)
            
            // Check image hash for each candidate
            for existingReceipt in existingReceipts {
                if let existingImageData = existingReceipt.imageData {
                    let existingHash = SHA256.hash(data: existingImageData)
                    let existingHashString = existingHash.compactMap { String(format: "%02x", $0) }.joined()
                    
                    if existingHashString == imageHashString {
                        // Update existing receipt with imageHash (if attribute exists)
                        existingReceipt.setValue(imageHashString, forKey: "imageHash")
                        print("[MultiItem] using receiptId: \(existingReceipt.id?.uuidString ?? "unknown") (reused)")
                        return existingReceipt
                    }
                }
            }
        } catch {
            print("❌ Error fetching existing receipts (fallback): \(error)")
        }
        
        // Create new receipt
        let receipt = Receipt(context: viewContext)
        receipt.id = UUID()
        receipt.title = "Receipt" // Generic title for multi-item receipt
        receipt.store = store
        receipt.purchaseDate = purchaseDate
        receipt.price = totalPrice
        receipt.imageData = imageData
        receipt.setValue(imageHashString, forKey: "imageHash") // Store hash for future deduplication
        receipt.createdAt = Date()
        
        if let receiptId = receipt.id {
            print("[MultiItem] using receiptId: \(receiptId.uuidString) (new)")
        }
        
        return receipt
    }
    
    private func createAppliancesFromLines(_ lines: [DetectedLine]) {
        guard !lines.isEmpty else { return }
        
        // This function is kept for backward compatibility but should use createAppliancesFromEditableItems
        // Convert lines to editable items and use the main creation function
        let editableItems = lines.map { line in
            EditableItem(
                id: line.id,
                title: extractApplianceName(from: line.text) ?? line.text,
                price: line.amount,
                warrantyMonths: 12,
                category: "",
                originalLineText: line.text,
                quantity: line.quantity
            )
        }
        createAppliancesFromEditableItems(editableItems)
    }
    
    private func extractApplianceName(from text: String) -> String? {
        // Try to extract a meaningful name from the line
        // Remove common prefixes/suffixes and price info
        var cleaned = text
        
        // Remove price patterns
        let currencySymbol = CurrencyManager.shared.currencySymbol
        let escapedSymbol = NSRegularExpression.escapedPattern(for: currencySymbol)
        let pricePattern = #"\#(escapedSymbol)?\d+(\.\d{2})?\s*"#
        cleaned = cleaned.replacingOccurrences(of: pricePattern, with: "", options: .regularExpression)
        
        // Remove quantity indicators
        cleaned = cleaned.replacingOccurrences(of: #"x\d+|×\d+|\d+x|\d+×"#, with: "", options: .regularExpression)
        
        // Trim and return
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }
    
    private func extractPrice(from string: String) -> Double? {
        let currencySymbol = CurrencyManager.shared.currencySymbol
        let escapedSymbol = NSRegularExpression.escapedPattern(for: currencySymbol)
        let pattern = #"\#(escapedSymbol)?(\d+(?:\.\d{2})?)"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(string.startIndex..<string.endIndex, in: string)
        
        if let match = regex?.firstMatch(in: string, range: range),
           let range = Range(match.range(at: 1), in: string) {
            return Double(string[range])
        }
        
        return nil
    }
    
    private func saveAppliance() {
        // Prevent multiple saves
        guard saveButtonState != .loading else {
            print("⚠️ Save already in progress")
            return
        }
        
        print("🔄 Starting save process...")
        
        // Validate all fields before saving
        let isValid = validationManager.validateApplianceForm(
            title: title,
            store: store,
            price: price,
            warrantyMonths: warrantyMonths,
            purchaseDate: purchaseDate
        )
        
        if !isValid {
            print("❌ Validation failed")
            showingValidationAlert = true
            
            // Haptic feedback for validation errors
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            saveButtonState = .idle
            return
        }
        
        print("✅ Validation passed")
        saveButtonState = .loading
        isSaving = true
        
        let appliance = NSEntityDescription.insertNewObject(forEntityName: "Appliance", into: viewContext)
        appliance.setValue(UUID(), forKey: "id")
        appliance.setValue(title.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "name")
        appliance.setValue(store.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "brand")
        appliance.setValue(model.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "model")
        appliance.setValue(serialNumber.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "serialNumber")
        appliance.setValue(purchaseDate, forKey: "purchaseDate")
        appliance.setValue(price, forKey: "price")
        appliance.setValue(Int16(warrantyMonths), forKey: "warrantyMonths")
        appliance.setValue(warrantySummary.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "warrantySummary")
        appliance.setValue(notes.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "notes")
        appliance.setValue(Date(), forKey: "createdAt")
        
        // Calculate expiry date
        if let expiryDate = Calendar.current.date(byAdding: .month, value: warrantyMonths, to: purchaseDate) {
            appliance.setValue(expiryDate, forKey: "warrantyExpiryDate")
        }
        
        print("💾 Attempting to save to Core Data...")
        do {
            try viewContext.save()
            print("✅ Save successful!")
            
            // Haptic feedback for successful save
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            // Store the saved appliance ID and navigate to detail view
            if let savedID = appliance.value(forKey: "id") as? UUID {
                DispatchQueue.main.async {
                    self.isSaving = false
                    self.saveButtonState = .success
                    self.savedApplianceID = savedID
                    self.navigateToDetail = true
                }
            } else {
                // Fallback: dismiss if we can't get the ID
                DispatchQueue.main.async {
                    self.isSaving = false
                    self.saveButtonState = .success
                    // Auto-revert handled by button style, but dismiss immediately
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        dismiss()
                    }
                }
            }
        } catch {
            print("❌ Error saving appliance: \(error)")
            print("Error details: \(error.localizedDescription)")
            isSaving = false
            saveButtonState = .idle
            
            // Haptic feedback for error
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
        }
    }
    
    // MARK: - Code Scanning Handling
    
    // Note: handleScannedCode is already defined above and shows an alert
    // The old barcode handling functions have been removed in favor of the new CodeScannerView
    
    private func resetForm() {
        // Set flag to prevent validation during reset
        isResetting = true
        
        // Clear validation errors first (synchronously)
        validationManager.clearErrors()
        
        // Reset all form fields
        title = ""
        store = ""
        purchaseDate = Date()
        price = 0.0
        warrantyMonths = 12
        selectedImage = nil
        imageData = nil
        selectedDeviceType = nil
        model = ""
        serialNumber = ""
        warrantySummary = ""
        notes = ""
        scannedCode = nil
        saveButtonState = .idle
        
        // Clear errors again after field changes have propagated
        // Then reset the flag to allow normal validation
        DispatchQueue.main.async {
            self.validationManager.clearErrors()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.isResetting = false
            }
        }
    }
    
    private func fetchAppliance(id: UUID) -> Appliance? {
        let fetchRequest = Appliance.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        return try? viewContext.fetch(fetchRequest).first
    }
    
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - Document Scanner View

struct DocumentScannerView: UIViewControllerRepresentable {
    let onScanComplete: (VNDocumentCameraScan) -> Void
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onScanComplete: onScanComplete)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onScanComplete: (VNDocumentCameraScan) -> Void
        
        init(onScanComplete: @escaping (VNDocumentCameraScan) -> Void) {
            self.onScanComplete = onScanComplete
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            print("[Scan] DocumentScanner: scan completed with \(scan.pageCount) pages")
            controller.dismiss(animated: true) {
                self.onScanComplete(scan)
            }
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("❌ [Scan] DocumentScanner error: \(error.localizedDescription)")
            controller.dismiss(animated: true)
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            print("[Scan] DocumentScanner cancelled")
            controller.dismiss(animated: true)
        }
    }
}

