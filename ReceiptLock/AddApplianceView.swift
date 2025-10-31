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
    @State private var selectedTab: AddMethod = .scanInvoice
    @StateObject private var validationManager = ValidationManager()
    @State private var showingValidationAlert = false
    @State private var model = ""
    @State private var serialNumber = ""
    @State private var warrantySummary = ""
    @State private var notes = ""
    @State private var isSaving = false
    @State private var showingSaveSuccessAlert = false
    @State private var showingBarcodeScanner = false
    @State private var scannedBarcode: String?
    @State private var scannedBarcodeType: String?
    
    enum AddMethod {
        case scanInvoice
        case manualEntry
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
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppTheme.extraLargeSpacing) {
                        // Scan receipt Section
                        scanInvoiceSection
                        
                        // Manual Entry Section
                        manualEntrySection
                    }
                    .padding(AppTheme.spacing)
                }
            }
            .navigationTitle("Add Appliance")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        saveAppliance()
                    } label: {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primary))
                        } else {
                            Text("Save")
                                .foregroundColor(AppTheme.primary)
                        }
                    }
                    .disabled(title.isEmpty || store.isEmpty || isSaving)
                }
            }
        }
        .onChange(of: selectedImage) { _, _ in
            Task {
                await loadImage()
            }
        }
        .alert("Validation Errors", isPresented: $showingValidationAlert) {
            Button("OK") {
                validationManager.clearErrors()
            }
        } message: {
            Text("Please fix the validation errors before saving.")
        }
        .alert("Success!", isPresented: $showingSaveSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Appliance saved successfully!")
        }
    }
    
    // MARK: - Scan Invoice Section
    private var scanInvoiceSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            Text("Scan receipt or barcode")
                .rlHeadline()
            
            Text("Use a photo, PDF, or scan a barcode/QR code—store, model and purchase date auto-fill.")
                .rlSubheadlineMuted()
            
            // Receipt scanning button
            PhotosPicker(selection: $selectedImage, matching: .images) {
                HStack(spacing: AppTheme.smallSpacing) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.title2)
                        .symbolRenderingMode(.monochrome)
                        .foregroundColor(.white)
                    
                    Text("Scan Receipt")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(AppTheme.spacing)
                .background(AppTheme.primary)
                .cornerRadius(AppTheme.cornerRadius)
                .opacity(isProcessingOCR ? 0.6 : 1.0)
            }
            .disabled(isProcessingOCR)
            
            // Barcode scanning button
            Button(action: {
                showingBarcodeScanner = true
            }) {
                HStack(spacing: AppTheme.smallSpacing) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.title2)
                        .symbolRenderingMode(.monochrome)
                        .foregroundColor(.white)
                    
                    Text("Scan Barcode/QR Code")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(AppTheme.spacing)
                .background(AppTheme.secondary)
                .cornerRadius(AppTheme.cornerRadius)
            }
            
            // Show scanned barcode info if available
            if let barcode = scannedBarcode, let type = scannedBarcodeType {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Scanned \(type): \(barcode)")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                    Spacer()
                    Button("Clear") {
                        scannedBarcode = nil
                        scannedBarcodeType = nil
                    }
                    .font(.caption)
                    .foregroundColor(AppTheme.primary)
                }
                .padding(AppTheme.smallSpacing)
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.smallCornerRadius)
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
        .padding(AppTheme.spacing)
        .cardBackground()
        .sheet(isPresented: $showingBarcodeScanner) {
            BarcodeScannerView(onCodeScanned: { code, type in
                handleScannedBarcode(code: code, type: type)
            })
        }
    }
    
    // MARK: - Manual Entry Section
    private var manualEntrySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            Text("Choose from \"Device Type\" or \"Brands\" to proceed")
                .rlSubheadline()
            
            // Tab Selection
            HStack(spacing: 0) {
                Button("Device Type") {
                    selectedTab = .manualEntry
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.smallSpacing)
                .background(selectedTab == .manualEntry ? AppTheme.primary : Color.clear)
                .foregroundColor(selectedTab == .manualEntry ? .white : AppTheme.secondaryText)
                .font(.subheadline)
                .cornerRadius(AppTheme.smallCornerRadius, corners: [.topLeft, .bottomLeft])
                
                Button("Brands") {
                    // TODO: Implement brands selection
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.smallSpacing)
                .background(Color.clear)
                .foregroundColor(AppTheme.secondaryText)
                .font(.subheadline)
                .cornerRadius(AppTheme.smallCornerRadius, corners: [.topRight, .bottomRight])
            }
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                    .stroke(AppTheme.secondaryText.opacity(0.2), lineWidth: 1)
            )
            
            if selectedTab == .manualEntry {
                // Device Type Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: AppTheme.spacing) {
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
                            .background(selectedDeviceType == deviceType ? deviceType.color.opacity(0.1) : AppTheme.cardBackground)
                            .cornerRadius(AppTheme.cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                    .stroke(selectedDeviceType == deviceType ? deviceType.color : AppTheme.secondaryText.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // Form Fields
                formFields
            }
        }
        .padding(AppTheme.spacing)
        .cardBackground()
    }
    
    // MARK: - Form Fields
    private var formFields: some View {
        VStack(spacing: AppTheme.spacing) {
            // Validation Error Banner
            ValidationErrorBanner(validationManager: validationManager)
                .animation(.easeInOut, value: validationManager.hasErrors())
            
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
                    validationManager: validationManager
                ) { value, fieldKey in
                    validationManager.validateRequired(value, fieldName: "Appliance name", fieldKey: fieldKey) &&
                    validationManager.validateApplianceName(value, fieldKey: fieldKey)
                }
                
                // Store Field
                ValidatedTextField(
                    title: "Retailer / Store Name",
                    placeholder: "e.g., Amazon, IKEA, Currys",
                    text: $store,
                    fieldKey: "store",
                    validationManager: validationManager
                ) { value, fieldKey in
                    validationManager.validateRequired(value, fieldName: "Store name", fieldKey: fieldKey) &&
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
                Text("Purchase Details")
                    .rlHeadline()
                
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
                Text("Warranty")
                    .rlHeadline()
                
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
        
        let request = VNRecognizeTextRequest { request, error in
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
        
        request.recognitionLevel = .accurate
        
        do {
            try VNImageRequestHandler(cgImage: uiImage.cgImage!, options: [:]).perform([request])
        } catch {
            print("Error performing OCR: \(error)")
        }
    }
    
    private func processOCRResults(_ strings: [String]) {
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
        guard !isSaving else {
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
            
            return
        }
        
        print("✅ Validation passed")
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
            
            // Reset saving state and show success alert
            print("🚪 Showing success alert...")
            DispatchQueue.main.async {
                self.isSaving = false
                self.showingSaveSuccessAlert = true
            }
        } catch {
            print("❌ Error saving appliance: \(error)")
            print("Error details: \(error.localizedDescription)")
            isSaving = false
            
            // Haptic feedback for error
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
        }
    }
    
    // MARK: - Barcode Handling
    
    private func handleScannedBarcode(code: String, type: AVMetadataObject.ObjectType) {
        scannedBarcode = code
        scannedBarcodeType = barcodeTypeDisplayName(type)
        
        // Auto-fill fields based on barcode type
        if type == .qr {
            // QR codes might contain JSON or URL data
            handleQRCode(code)
        } else {
            // Standard barcodes (EAN, UPC, etc.) - typically product identifiers
            handleProductBarcode(code)
        }
        
        // Dismiss scanner
        showingBarcodeScanner = false
    }
    
    private func handleQRCode(_ code: String) {
        // Check if QR code is a URL
        if let url = URL(string: code), url.scheme != nil {
            // URL-based QR code - could be product page
            notes = "Product URL: \(code)"
            return
        }
        
        // Check if QR code is JSON
        if let data = code.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            // Extract data from JSON QR code
            if let productName = json["name"] as? String {
                title = productName
            }
            if let productModel = json["model"] as? String {
                model = productModel
            }
            if let productStore = json["store"] as? String {
                store = productStore
            }
            return
        }
        
        // Plain text QR code - use as model or serial number
        if model.isEmpty {
            model = code
        } else if serialNumber.isEmpty {
            serialNumber = code
        } else {
            notes = "QR Code: \(code)"
        }
    }
    
    private func handleProductBarcode(_ code: String) {
        // Standard product barcodes (EAN-13, UPC, etc.)
        // Use the barcode as a product identifier
        // In a real app, you might look this up in a product database
        
        // For now, store it in notes or use as model identifier
        if model.isEmpty {
            // Try to infer product type from barcode if possible
            model = "Product ID: \(code)"
        } else {
            notes = "Barcode: \(code)"
        }
        
        // You could also use the barcode to look up product information
        // from an external API or database here
    }
    
    private func barcodeTypeDisplayName(_ type: AVMetadataObject.ObjectType) -> String {
        switch type {
        case .qr:
            return "QR Code"
        case .ean13:
            return "EAN-13"
        case .ean8:
            return "EAN-8"
        case .code128:
            return "Code 128"
        case .code39:
            return "Code 39"
        case .code93:
            return "Code 93"
        case .upce:
            return "UPC-E"
        case .pdf417:
            return "PDF417"
        case .aztec:
            return "Aztec"
        case .dataMatrix:
            return "Data Matrix"
        default:
            return "Barcode"
        }
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
