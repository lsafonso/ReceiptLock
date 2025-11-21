//
//  ValidationSystem.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI
import Foundation

// MARK: - Validation Error Types
enum ValidationError: LocalizedError {
    case emptyField(fieldName: String)
    case invalidPrice
    case invalidWarrantyMonths
    case invalidDate
    case futureDateRequired
    case priceTooHigh
    case warrantyTooLong
    case invalidStoreName
    case invalidApplianceName
    
    var errorDescription: String? {
        switch self {
        case .emptyField(let fieldName):
            return "\(fieldName) cannot be empty"
        case .invalidPrice:
            return "Please enter a valid price (e.g., 299.99)"
        case .invalidWarrantyMonths:
            return "Warranty must be between 1 and 120 months"
        case .invalidDate:
            return "Please enter a valid date"
        case .futureDateRequired:
            return "Purchase date cannot be in the future"
        case .priceTooHigh:
            return "Price cannot exceed \(CurrencyManager.shared.currencySymbol)999,999"
        case .warrantyTooLong:
            return "Warranty cannot exceed 10 years"
        case .invalidStoreName:
            return "Store name must be between 2 and 50 characters"
        case .invalidApplianceName:
            return "Appliance name must be between 2 and 100 characters"
        }
    }
}

// MARK: - Validation Rules
struct ValidationRules {
    static let maxPrice: Double = 999_999.0
    static let maxWarrantyMonths: Int = 120
    static let minWarrantyMonths: Int = 1
    static let maxStoreNameLength: Int = 50
    static let minStoreNameLength: Int = 2
    static let maxApplianceNameLength: Int = 100
    static let minApplianceNameLength: Int = 2
}

// MARK: - Validation Manager
class ValidationManager: ObservableObject {
    @Published var errors: [String: ValidationError] = [:]
    @Published var isValidating = false
    
    // MARK: - Validation Methods
    
    func validateRequired(_ value: String, fieldName: String, fieldKey: String) -> Bool {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedValue.isEmpty {
            errors[fieldKey] = .emptyField(fieldName: fieldName)
            return false
        } else {
            errors.removeValue(forKey: fieldKey)
            return true
        }
    }
    
    func validatePrice(_ price: Double, fieldKey: String) -> Bool {
        if price < 0 {
            errors[fieldKey] = .invalidPrice
            return false
        } else if price > ValidationRules.maxPrice {
            errors[fieldKey] = .priceTooHigh
            return false
        } else {
            errors.removeValue(forKey: fieldKey)
            return true
        }
    }
    
    func validateWarrantyMonths(_ months: Int, fieldKey: String) -> Bool {
        if months < ValidationRules.minWarrantyMonths || months > ValidationRules.maxWarrantyMonths {
            errors[fieldKey] = .invalidWarrantyMonths
            return false
        } else {
            errors.removeValue(forKey: fieldKey)
            return true
        }
    }
    
    func validatePurchaseDate(_ date: Date, fieldKey: String) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.compare(date, to: now, toGranularity: .day) == .orderedDescending {
            errors[fieldKey] = .futureDateRequired
            return false
        } else {
            errors.removeValue(forKey: fieldKey)
            return true
        }
    }
    
    func validateStoreName(_ name: String, fieldKey: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.count < ValidationRules.minStoreNameLength {
            errors[fieldKey] = .invalidStoreName
            return false
        } else if trimmedName.count > ValidationRules.maxStoreNameLength {
            errors[fieldKey] = .invalidStoreName
            return false
        } else {
            errors.removeValue(forKey: fieldKey)
            return true
        }
    }
    
    func validateApplianceName(_ name: String, fieldKey: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.count < ValidationRules.minApplianceNameLength {
            errors[fieldKey] = .invalidApplianceName
            return false
        } else if trimmedName.count > ValidationRules.maxApplianceNameLength {
            errors[fieldKey] = .invalidApplianceName
            return false
        } else {
            errors.removeValue(forKey: fieldKey)
            return true
        }
    }
    
    // MARK: - Form Validation
    
    func validateApplianceForm(
        title: String,
        store: String,
        price: Double,
        warrantyMonths: Int,
        purchaseDate: Date
    ) -> Bool {
        var isValid = true
        
        isValid = validateRequired(title, fieldName: "Appliance name", fieldKey: "title") && isValid
        isValid = validateApplianceName(title, fieldKey: "title") && isValid
        isValid = validateRequired(store, fieldName: "Store name", fieldKey: "store") && isValid
        isValid = validateStoreName(store, fieldKey: "store") && isValid
        isValid = validatePrice(price, fieldKey: "price") && isValid
        isValid = validateWarrantyMonths(warrantyMonths, fieldKey: "warranty") && isValid
        isValid = validatePurchaseDate(purchaseDate, fieldKey: "date") && isValid
        
        return isValid
    }
    
    func clearErrors() {
        errors.removeAll()
    }
    
    func getError(for fieldKey: String) -> ValidationError? {
        return errors[fieldKey]
    }
    
    func hasErrors() -> Bool {
        return !errors.isEmpty
    }
}

// MARK: - Validated Text Field
struct ValidatedTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let fieldKey: String
    @ObservedObject var validationManager: ValidationManager
    let validationRule: (String, String) -> Bool
    var skipValidation: Bool = false
    
    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        fieldKey: String,
        validationManager: ValidationManager,
        skipValidation: Bool = false,
        validationRule: @escaping (String, String) -> Bool
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.fieldKey = fieldKey
        self.validationManager = validationManager
        self.skipValidation = skipValidation
        self.validationRule = validationRule
    }
    
    var body: some View {
        ReceiptLockTextField(
            title: title,
            placeholder: placeholder,
            text: $text,
            hasError: validationManager.getError(for: fieldKey) != nil,
            errorMessage: validationManager.getError(for: fieldKey)?.errorDescription
        )
        .onChange(of: text) { _, newValue in
            if !skipValidation {
                _ = validationRule(newValue, fieldKey)
            } else {
                // Clear error for this field when skipping validation (during reset)
                validationManager.errors.removeValue(forKey: fieldKey)
            }
        }
    }
}

// MARK: - Validated Price Field
struct ValidatedPriceField: View {
    let title: String
    @Binding var price: Double
    let fieldKey: String
    @ObservedObject var validationManager: ValidationManager
    @State private var priceText: String = ""
    @FocusState private var isFocused: Bool
    
    // UK locale for currency formatting
    private static let ukLocale = Locale(identifier: "en_GB")
    
    // Get locale decimal separator
    private var decimalSeparator: String {
        Self.ukLocale.decimalSeparator ?? "."
    }
    
    init(
        title: String,
        price: Binding<Double>,
        fieldKey: String,
        validationManager: ValidationManager
    ) {
        self.title = title
        self._price = price
        self.fieldKey = fieldKey
        self.validationManager = validationManager
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
        VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppTheme.text)
                
                if validationManager.getError(for: fieldKey) != nil {
                    Text("*")
                        .font(.headline)
                        .foregroundColor(AppTheme.error)
                }
                
                Spacer()
            }
            
            HStack {
                Text(CurrencyManager.shared.currencySymbol)
                    .font(.body)
                    .foregroundColor(AppTheme.secondaryText)
                
                TextField("0.00", text: $priceText)
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
                                validationManager.errors.removeValue(forKey: fieldKey)
                            } else if let decimalValue = parseRawPrice(newValue) {
                                // Parse to Decimal, convert to Double for model
                                price = NSDecimalNumber(decimal: decimalValue).doubleValue
                                _ = validationManager.validatePrice(price, fieldKey: fieldKey)
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
                            validationManager.errors.removeValue(forKey: fieldKey)
                        } else if let decimalValue = parseRawPrice(cleaned) {
                            price = NSDecimalNumber(decimal: decimalValue).doubleValue
                            _ = validationManager.validatePrice(price, fieldKey: fieldKey)
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
                                validationManager.errors.removeValue(forKey: fieldKey)
                            } else if let decimalValue = parseRawPrice(priceText) {
                                // Parse succeeded - format with currency formatter
                                if let formatted = formatPriceForDisplay(decimalValue) {
                                    priceText = formatted
                                    price = NSDecimalNumber(decimal: decimalValue).doubleValue
                                    _ = validationManager.validatePrice(price, fieldKey: fieldKey)
                                } else {
                                    // Format failed but parse succeeded - update price, leave text as-is
                                    price = NSDecimalNumber(decimal: decimalValue).doubleValue
                                    _ = validationManager.validatePrice(price, fieldKey: fieldKey)
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
                                validationManager.errors.removeValue(forKey: fieldKey)
                            } else if let decimalValue = Decimal(string: String(newValue), locale: Self.ukLocale),
                                      let formatted = formatPriceForDisplay(decimalValue) {
                                priceText = formatted
                            }
                        }
                    }
            }
            .padding(.horizontal, AppTheme.spacing)
            .padding(.vertical, AppTheme.smallSpacing)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .fill(AppTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                            .stroke(
                                validationManager.getError(for: fieldKey) != nil ? AppTheme.error : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
            
            if let error = validationManager.getError(for: fieldKey) {
                Text(error.errorDescription ?? "")
                    .font(.caption)
                    .foregroundColor(AppTheme.error)
                    .padding(.horizontal, AppTheme.spacing)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Validated Stepper Field
struct ValidatedStepperField: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let fieldKey: String
    @ObservedObject var validationManager: ValidationManager
    let validationRule: (Int, String) -> Bool
    
    init(
        title: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        fieldKey: String,
        validationManager: ValidationManager,
        validationRule: @escaping (Int, String) -> Bool
    ) {
        self.title = title
        self._value = value
        self.range = range
        self.fieldKey = fieldKey
        self.validationManager = validationManager
        self.validationRule = validationRule
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppTheme.text)
                
                if validationManager.getError(for: fieldKey) != nil {
                    Text("*")
                        .font(.headline)
                        .foregroundColor(AppTheme.error)
                }
                
                Spacer()
                
                Text("\(value)")
                    .font(.headline)
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            // Only the stepper control area has green background
            Stepper("", value: $value, in: range)
                .labelsHidden()
                .accentColor(.white)
                .colorScheme(.dark)
                .symbolRenderingMode(.monochrome)
                .padding(.horizontal, AppTheme.smallSpacing)
                .padding(.vertical, AppTheme.smallSpacing / 2)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                        .fill(AppTheme.primary)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                                .stroke(
                                    validationManager.getError(for: fieldKey) != nil ? AppTheme.error : Color.clear,
                                    lineWidth: 1
                                )
                        )
                )
                .onChange(of: value) { _, newValue in
                    _ = validationRule(newValue, fieldKey)
                }
        }
        
        if let error = validationManager.getError(for: fieldKey) {
            Text(error.errorDescription ?? "")
                .font(.caption)
                .foregroundColor(AppTheme.error)
                .padding(.horizontal, AppTheme.spacing)
                .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
}

// MARK: - Validated Date Field
struct ValidatedDateField: View {
    let title: String
    @Binding var date: Date
    let fieldKey: String
    @ObservedObject var validationManager: ValidationManager
    
    init(
        title: String,
        date: Binding<Date>,
        fieldKey: String,
        validationManager: ValidationManager
    ) {
        self.title = title
        self._date = date
        self.fieldKey = fieldKey
        self.validationManager = validationManager
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppTheme.text)
                
                if validationManager.getError(for: fieldKey) != nil {
                    Text("*")
                        .font(.headline)
                        .foregroundColor(AppTheme.error)
                }
                
                Spacer()
            }
            
            // Only the date picker control area has green background
            DatePicker(
                "",
                selection: $date,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .accentColor(.white)
            .colorScheme(.dark)
            .padding(.horizontal, AppTheme.smallSpacing)
            .padding(.vertical, AppTheme.smallSpacing / 2)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.field)
                    .fill(AppTheme.primary)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.field)
                            .stroke(
                                validationManager.getError(for: fieldKey) != nil ? AppTheme.error : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
            .onChange(of: date) { _, newValue in
                _ = validationManager.validatePurchaseDate(newValue, fieldKey: fieldKey)
            }
        }
        
        if let error = validationManager.getError(for: fieldKey) {
            Text(error.errorDescription ?? "")
                .font(.caption)
                .foregroundColor(AppTheme.error)
                .padding(.horizontal, AppTheme.spacing)
                .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
}

// MARK: - Validation Error Banner
struct ValidationErrorBanner: View {
    @ObservedObject var validationManager: ValidationManager
    
    var body: some View {
        if validationManager.hasErrors() {
            VStack(spacing: AppTheme.smallSpacing) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(AppTheme.error)
                    
                    Text("Please fix the following errors:")
                        .font(.headline)
                        .foregroundColor(AppTheme.error)
                    
                    Spacer()
                }
                
                ForEach(Array(validationManager.errors.values), id: \.errorDescription) { error in
                    HStack {
                        Text("•")
                            .foregroundColor(AppTheme.error)
                        
                        Text(error.errorDescription ?? "")
                            .font(.body)
                            .foregroundColor(AppTheme.error)
                        
                        Spacer()
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .fill(AppTheme.error.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                            .stroke(AppTheme.error, lineWidth: 1)
                    )
            )
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
