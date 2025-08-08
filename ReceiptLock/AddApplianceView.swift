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
                    VStack(spacing: AppTheme.largeSpacing) {
                        // Scan Invoice Section
                        scanInvoiceSection
                        
                        // Separator
                        separator
                        
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
                    Button("Save") {
                        saveAppliance()
                    }
                    .foregroundColor(AppTheme.primary)
                    .disabled(title.isEmpty || store.isEmpty)
                }
            }
        }
        .onChange(of: selectedImage) { _, _ in
            Task {
                await loadImage()
            }
        }
    }
    
    // MARK: - Scan Invoice Section
    private var scanInvoiceSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            Text("Scan Invoice")
                .font(.headline.weight(.semibold))
                .foregroundColor(AppTheme.text)
            
            Text("Use invoice image or pdf to autofill details")
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText)
            
            PhotosPicker(selection: $selectedImage, matching: .images) {
                HStack(spacing: AppTheme.smallSpacing) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.title2)
                    
                    Text("Scan Invoice")
                        .font(.headline.weight(.semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(AppTheme.spacing)
                .background(AppTheme.primary)
                .cornerRadius(AppTheme.cornerRadius)
            }
            .disabled(isProcessingOCR)
            
            if isProcessingOCR {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Processing invoice...")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
        }
        .padding(AppTheme.spacing)
        .cardBackground()
    }
    
    // MARK: - Separator
    private var separator: some View {
        HStack {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AppTheme.secondaryText.opacity(0.3))
            
            Text("OR")
                .font(.caption.weight(.medium))
                .foregroundColor(AppTheme.secondaryText)
                .padding(.horizontal, AppTheme.spacing)
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AppTheme.secondaryText.opacity(0.3))
        }
    }
    
    // MARK: - Manual Entry Section
    private var manualEntrySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            Text("Choose from \"Device Type\" or \"Brands\" to proceed")
                .font(.subheadline)
                .foregroundColor(AppTheme.text)
            
            // Tab Selection
            HStack(spacing: 0) {
                Button("Device Type") {
                    selectedTab = .manualEntry
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.smallSpacing)
                .background(selectedTab == .manualEntry ? AppTheme.primary : AppTheme.cardBackground)
                .foregroundColor(selectedTab == .manualEntry ? .white : AppTheme.text)
                .cornerRadius(AppTheme.smallCornerRadius, corners: [.topLeft, .bottomLeft])
                
                Button("Brands") {
                    // TODO: Implement brands selection
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.smallSpacing)
                .background(AppTheme.cardBackground)
                .foregroundColor(AppTheme.text)
                .cornerRadius(AppTheme.smallCornerRadius, corners: [.topRight, .bottomRight])
            }
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                    .stroke(AppTheme.secondaryText.opacity(0.3), lineWidth: 1)
            )
            
            if selectedTab == .manualEntry {
                // Device Type Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: AppTheme.spacing) {
                    ForEach(DeviceType.allCases, id: \.self) { deviceType in
                        Button(action: {
                            selectedDeviceType = deviceType
                            title = deviceType.rawValue
                        }) {
                            VStack(spacing: AppTheme.smallSpacing) {
                                Image(systemName: deviceType.icon)
                                    .font(.title2)
                                    .foregroundColor(deviceType.color)
                                
                                Text(deviceType.rawValue)
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(AppTheme.text)
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
            VStack(alignment: .leading, spacing: 4) {
                Text("Appliance Name")
                    .font(.caption.weight(.medium))
                    .foregroundColor(AppTheme.secondaryText)
                
                TextField("Enter appliance name", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Store/Brand")
                    .font(.caption.weight(.medium))
                    .foregroundColor(AppTheme.secondaryText)
                
                TextField("Enter store or brand", text: $store)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Purchase Date")
                    .font(.caption.weight(.medium))
                    .foregroundColor(AppTheme.secondaryText)
                
                DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Price")
                    .font(.caption.weight(.medium))
                    .foregroundColor(AppTheme.secondaryText)
                
                TextField("Enter price", value: $price, format: .currency(code: "USD"))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Warranty Duration (months)")
                    .font(.caption.weight(.medium))
                    .foregroundColor(AppTheme.secondaryText)
                
                Stepper("\(warrantyMonths) months", value: $warrantyMonths, in: 1...60)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(AppTheme.smallCornerRadius)
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
        
        // Extract price if found
        for string in strings {
            if let priceValue = extractPrice(from: string) {
                price = priceValue
                break
            }
        }
    }
    
    private func extractPrice(from string: String) -> Double? {
        let pattern = #"\$?(\d+(?:\.\d{2})?)"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(string.startIndex..<string.endIndex, in: string)
        
        if let match = regex?.firstMatch(in: string, range: range),
           let range = Range(match.range(at: 1), in: string) {
            return Double(string[range])
        }
        
        return nil
    }
    
    private func saveAppliance() {
        let receipt = Receipt(context: viewContext)
        receipt.id = UUID()
        receipt.title = title
        receipt.store = store
        receipt.purchaseDate = purchaseDate
        receipt.price = price
        receipt.warrantyMonths = Int16(warrantyMonths)
        receipt.createdAt = Date()
        
        // Note: imageData property doesn't exist in Receipt entity
        // In a real app, you would save the image to Documents directory
        // and store the file path in the receipt
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving appliance: \(error)")
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
