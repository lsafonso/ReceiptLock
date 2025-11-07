//
//  EditApplianceView.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI

struct EditApplianceView: View {
    let appliance: Appliance
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var brand: String
    @State private var model: String
    @State private var serialNumber: String
    @State private var purchaseDate: Date
    @State private var price: Double
    @State private var warrantyMonths: Int
    @State private var notes: String
    @State private var warrantySummary: String
    @State private var showingSaveSuccessAlert = false
    @State private var isSaving = false
    @State private var saveButtonState: SaveButtonState = .idle
    
    private var hasUnsavedChanges: Bool {
        title != (appliance.name ?? "") ||
        brand != (appliance.brand ?? "") ||
        model != (appliance.model ?? "") ||
        serialNumber != (appliance.serialNumber ?? "") ||
        price != appliance.price ||
        warrantyMonths != Int(appliance.warrantyMonths) ||
        notes != (appliance.notes ?? "") ||
        warrantySummary != (appliance.warrantySummary ?? "") ||
        !Calendar.current.isDate(purchaseDate, inSameDayAs: appliance.purchaseDate ?? Date())
    }
    
    init(appliance: Appliance) {
        self.appliance = appliance
        self._title = State(initialValue: appliance.name ?? "")
        self._brand = State(initialValue: appliance.brand ?? "")
        self._model = State(initialValue: appliance.model ?? "")
        self._serialNumber = State(initialValue: appliance.serialNumber ?? "")
        self._purchaseDate = State(initialValue: appliance.purchaseDate ?? Date())
        self._price = State(initialValue: appliance.price)
        self._warrantyMonths = State(initialValue: Int(appliance.warrantyMonths))
        self._notes = State(initialValue: appliance.notes ?? "")
        self._warrantySummary = State(initialValue: appliance.warrantySummary ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Appliance Name", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Brand", text: $brand)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Model", text: $model)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Serial Number", text: $serialNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section("Purchase Details") {
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                    
                    PriceTextField(price: $price)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section("Warranty") {
                    Stepper("\(warrantyMonths) months", value: $warrantyMonths, in: 1...60)
                    
                    TextField("Warranty Summary", text: $warrantySummary, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                
                Section("Additional Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Appliance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CancelButton(action: { dismiss() }, hasUnsavedChanges: hasUnsavedChanges)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        saveChanges()
                    } label: {
                        Text("Save")
                    }
                    .buttonStyle(PrimarySaveButtonStyle(state: saveButtonState))
                    .disabled(title.isEmpty || brand.isEmpty || saveButtonState == .loading)
                    .opacity((title.isEmpty || brand.isEmpty || saveButtonState == .loading) ? 0.4 : 1.0)
                }
            }
        }
        .alert("Success!", isPresented: $showingSaveSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Appliance updated successfully!")
        }
    }
    
    private func saveChanges() {
        guard saveButtonState != .loading else { return }
        
        saveButtonState = .loading
        isSaving = true
        
        appliance.name = title
        appliance.brand = brand
        appliance.model = model
        appliance.serialNumber = serialNumber
        appliance.purchaseDate = purchaseDate
        appliance.price = price
        appliance.warrantyMonths = Int16(warrantyMonths)
        appliance.notes = notes
        appliance.warrantySummary = warrantySummary
        appliance.updatedAt = Date()
        
        // Calculate expiry date based on purchase date and warranty months
        if warrantyMonths > 0, let expiryDate = Calendar.current.date(byAdding: .month, value: warrantyMonths, to: purchaseDate) {
            appliance.warrantyExpiryDate = expiryDate
        } else {
            appliance.warrantyExpiryDate = nil
        }
        
        do {
            try viewContext.save()
            
            // Haptic feedback for successful save
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            // Show success state then alert
            DispatchQueue.main.async {
                self.isSaving = false
                self.saveButtonState = .success
                // Auto-revert will happen after 0.8s, then show alert
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    self.showingSaveSuccessAlert = true
                }
            }
        } catch {
            print("Error saving changes: \(error)")
            isSaving = false
            saveButtonState = .idle
            
            // Haptic feedback for error
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
        }
    }
}

// MARK: - Price Text Field (Format on Blur)
struct PriceTextField: View {
    @Binding var price: Double
    @State private var priceText: String = ""
    @FocusState private var isFocused: Bool
    
    // UK locale for currency formatting
    private static let ukLocale = Locale(identifier: "en_GB")
    
    // Get locale decimal separator
    private var decimalSeparator: String {
        Self.ukLocale.decimalSeparator ?? "."
    }
    
    init(price: Binding<Double>) {
        self._price = price
        // Initialize with raw string (no formatting)
        let rawValue = price.wrappedValue == 0.0 ? "" : formatRawPrice(price.wrappedValue)
        self._priceText = State(initialValue: rawValue)
    }
    
    // Convert formatted price to raw editable string (strip currency symbols, formatting)
    private func formatRawPrice(_ value: Double) -> String {
        if value == 0.0 { return "" }
        // Remove trailing zeros and unnecessary decimal point
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Self.ukLocale
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
    
    // Strip currency symbols and formatting from text to get raw editable string
    private func stripToRaw(_ text: String) -> String {
        // Remove currency symbols, spaces, and non-numeric characters except decimal separator
        var cleaned = text
        // Remove common currency symbols
        cleaned = cleaned.replacingOccurrences(of: CurrencyManager.shared.currencySymbol, with: "")
        cleaned = cleaned.replacingOccurrences(of: "£", with: "")
        cleaned = cleaned.replacingOccurrences(of: "$", with: "")
        cleaned = cleaned.replacingOccurrences(of: "€", with: "")
        cleaned = cleaned.replacingOccurrences(of: " ", with: "")
        // Keep only digits and decimal separators
        cleaned = cleaned.filter { $0.isNumber || $0 == "." || $0 == "," }
        // Normalize decimal separator
        cleaned = cleaned.replacingOccurrences(of: ",", with: ".")
        // Ensure only one decimal point
        let components = cleaned.components(separatedBy: ".")
        if components.count > 2 {
            cleaned = components[0] + "." + components.dropFirst().joined()
        }
        return cleaned
    }
    
    // Convert raw string to Decimal, normalizing decimal separator
    private func parseRawPrice(_ text: String) -> Decimal? {
        let normalized = text.replacingOccurrences(of: ",", with: ".")
        // Remove any non-numeric characters except decimal point
        let cleaned = normalized.filter { $0.isNumber || $0 == "." }
        guard !cleaned.isEmpty else { return nil }
        return Decimal(string: cleaned, locale: Self.ukLocale)
    }
    
    // Format price for display using currency formatter (on blur)
    private func formatPriceForDisplay(_ value: Decimal) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Self.ukLocale
        formatter.currencyCode = CurrencyManager.shared.currencyCode
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: value as NSDecimalNumber)
    }
    
    var body: some View {
        TextField("Price", text: $priceText)
            .keyboardType(.decimalPad)
            .autocorrectionDisabled()
            .focused($isFocused)
            .onChange(of: priceText) { oldValue, newValue in
                // While focused: NO formatting, only normalize pasted invalid input
                // Allow free typing - don't mutate text during normal typing
                
                // Check if input is valid (only digits and one decimal separator)
                let isValidInput = newValue.allSatisfy { $0.isNumber || $0 == "." || $0 == "," }
                let hasOnlyOneDecimal = newValue.filter { $0 == "." || $0 == "," }.count <= 1
                
                if isValidInput && hasOnlyOneDecimal {
                    // Valid input - just parse and update model silently, don't modify text
                    if newValue.isEmpty {
                        // Empty state: keep empty, don't set price to 0
                        // Price model stays as-is (will be validated on blur/submit)
                    } else if let decimalValue = parseRawPrice(newValue) {
                        // Parse to Decimal, convert to Double for model
                        price = NSDecimalNumber(decimal: decimalValue).doubleValue
                    }
                    return
                }
                
                // Invalid input (likely pasted) - normalize but avoid cursor jump
                // Only normalize commas/periods, filter invalid chars
                let cleaned = stripToRaw(newValue)
                
                // Update text only if we actually changed something
                if priceText != cleaned {
                    priceText = cleaned
                }
                
                // Parse and update price model
                if cleaned.isEmpty {
                    // Empty - price stays as-is
                } else if let decimalValue = parseRawPrice(cleaned) {
                    price = NSDecimalNumber(decimal: decimalValue).doubleValue
                }
            }
            .onChange(of: isFocused) { oldValue, newValue in
                if newValue {
                    // On focus: strip currency/symbols back to raw editable string
                    let raw = stripToRaw(priceText)
                    if priceText != raw {
                        priceText = raw
                    }
                } else {
                    // On blur: parse to Decimal and format once with currency formatter
                    if priceText.isEmpty {
                        // Empty stays empty - don't auto-fill 0 or "£ 0.00"
                        price = 0.0
                    } else if let decimalValue = parseRawPrice(priceText) {
                        // Parse succeeded - format with currency formatter
                        if let formatted = formatPriceForDisplay(decimalValue) {
                            priceText = formatted
                            price = NSDecimalNumber(decimal: decimalValue).doubleValue
                        } else {
                            // Format failed but parse succeeded - update price, leave text as-is
                            price = NSDecimalNumber(decimal: decimalValue).doubleValue
                        }
                    } else {
                        // Parse failed - leave text as-is, don't update price
                        // User can fix it on next focus
                    }
                }
            }
            .onChange(of: price) { oldValue, newValue in
                // When price changes externally (e.g., form reset), update text
                // Only update if not focused to avoid interfering with typing
                if !isFocused {
                    if newValue == 0.0 {
                        priceText = ""
                    } else if let decimalValue = Decimal(string: String(newValue), locale: Self.ukLocale),
                              let formatted = formatPriceForDisplay(decimalValue) {
                        priceText = formatted
                    }
                }
            }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let appliance = Appliance(context: context)
    appliance.name = "Sample Appliance"
    appliance.brand = "Sample Brand"
    appliance.model = "Sample Model"
    appliance.purchaseDate = Date()
    appliance.price = 999.99
    appliance.warrantyMonths = 24
    
    return EditApplianceView(appliance: appliance)
        .environment(\.managedObjectContext, context)
}
