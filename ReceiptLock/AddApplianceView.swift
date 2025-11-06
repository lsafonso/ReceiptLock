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
    @State private var ocrError: String?
    @State private var showingOCRError = false
    @State private var selectedPDFURL: URL?
    @State private var showingFileImporter = false
    @State private var detectedLines: [DetectedLine] = []
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
                        
                        // Scan receipt Section
                        scanInvoiceSection
                            .padding(.horizontal, 24) // 24pt side insets for card alignment
                            .padding(.top, 24) // H1→intro block gap 24pt
                        
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
            guard let newValue = newValue else { return }
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
            .disabled(isProcessingOCR)
            .accessibilityLabel("Scan or import a receipt or barcode")
            .accessibilityHint("Opens options to scan with the camera or import from your library.")
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
            DetectedReceiptItemsView(
                lines: detectedLines,
                onContinue: { selectedLines in
                    handleBatchCreation(selectedLines: selectedLines)
                }
            )
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
        print("[Scan] camera presented")
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            showingReceiptCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.showingReceiptCamera = true
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
    
    private func presentCodeScanner() {
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
        // Try PhotosPicker first (for images), and also show file importer option
        showingPhotoPicker = true
        // Note: User can also access PDFs via fileImporter if needed
        // For now, we'll handle PDFs through a separate flow if PhotosPicker doesn't support them
    }
    
    private func handlePDFSelection(result: Result<[URL], Error>) {
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
            
            // Store the PDF URL for reference
            await MainActor.run {
                self.selectedPDFURL = url
                if let imageData = firstPageImage.jpegData(compressionQuality: 0.9) {
                    self.imageData = imageData
                }
            }
            
            // Process the first page with OCR
            print("[OCR] start")
            processImageWithOCR(firstPageImage)
            
        } catch {
            print("❌ [Import] PDF processing error: \(error.localizedDescription)")
            await MainActor.run {
                self.isProcessingOCR = false
                self.ocrError = "Failed to process PDF"
                self.showingOCRError = true
            }
        }
    }
    
    // MARK: - Image Processing
    
    private func handleCapturedImage(_ image: UIImage) {
        // Convert UIImage to Data
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
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
        
        processImageWithOCR(image)
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
            
            // Process OCR results
            DispatchQueue.main.async {
                self.processOCRResults(recognizedStrings)
                self.isProcessingOCR = false
                print("[OCR] done")
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
                        .cornerRadius(12) // Mini card radius 12
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
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
            
            // Process OCR results to extract appliance details
            DispatchQueue.main.async {
                self.processOCRResults(recognizedStrings)
            }
        }
        
        request.recognitionLevel = VNRequestTextRecognitionLevel.accurate
        
        do {
            try VNImageRequestHandler(cgImage: uiImage.cgImage!, options: [:]).perform([request])
        } catch {
            print("Error performing OCR: \(error)")
        }
    }
    
    private func processOCRResults(_ strings: [String]) {
        // Combine all strings into raw OCR text
        let rawOCR = strings.joined(separator: "\n")
        
        // Parse into candidate lines
        let candidateLines = parseDetectedLines(from: rawOCR)
        
        print("[MultiItem] candidates: \(candidateLines.count)")
        
        // If we detected multiple lines, show the selection UI
        if candidateLines.count > 1 {
            detectedLines = candidateLines
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
    
    private func parseDetectedLines(from rawOCR: String) -> [DetectedLine] {
        // Split by line breaks
        let lines = rawOCR.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var detectedLines: [DetectedLine] = []
        
        // Brand/model tokens to look for (common appliance/product keywords)
        let brandTokens = ["samsung", "apple", "iphone", "ipad", "sony", "lg", "panasonic", "bosch", "whirlpool", "hotpoint", "beko", "indesit", "miele", "dyson", "dyson", "philips", "kenwood", "kitchenaid", "breville", "ninja", "instant", "air fryer", "microwave", "oven", "fridge", "refrigerator", "washing machine", "dishwasher", "laptop", "tablet", "tv", "television", "monitor", "speaker", "headphone", "camera", "printer", "desktop", "mobile", "phone"]
        
        // Price pattern: £?\d+(\.\d{2})?
        let currencySymbol = CurrencyManager.shared.currencySymbol
        let escapedSymbol = NSRegularExpression.escapedPattern(for: currencySymbol)
        let pricePattern = #"\#(escapedSymbol)?\d+(\.\d{2})?"#
        
        for line in lines {
            let lowercasedLine = line.lowercased()
            
            // Check if line contains brand tokens or price pattern
            let hasBrandToken = brandTokens.contains { lowercasedLine.contains($0) }
            let hasPrice = (try? NSRegularExpression(pattern: pricePattern)).flatMap { regex in
                let range = NSRange(location: 0, length: line.utf16.count)
                return regex.firstMatch(in: line, range: range) != nil
            } ?? false
            
            if hasBrandToken || hasPrice {
                // Extract amount if present
                var amount: Decimal? = nil
                if let priceValue = extractPrice(from: line) {
                    amount = Decimal(priceValue)
                }
                
                // Extract quantity if present (x2, 2×, etc.)
                var quantity = 1
                if let qtyMatch = line.range(of: #"x\d+|×\d+|\d+x|\d+×"#, options: .regularExpression) {
                    let qtyString = String(line[qtyMatch])
                        .replacingOccurrences(of: "x", with: "", options: .caseInsensitive)
                        .replacingOccurrences(of: "×", with: "")
                    if let qty = Int(qtyString) {
                        quantity = qty
                    }
                }
                
                detectedLines.append(DetectedLine(
                    text: line,
                    amount: amount,
                    quantity: quantity
                ))
            }
        }
        
        return detectedLines
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

