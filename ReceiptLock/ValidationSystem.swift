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
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, AppTheme.spacing)
                .padding(.vertical, AppTheme.smallSpacing)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .fill(AppTheme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                .stroke(
                                    validationManager.getError(for: fieldKey) != nil ? AppTheme.error : AppTheme.separator,
                                    lineWidth: 1
                                )
                        )
                )
                .onChange(of: text) { _, newValue in
                    if !skipValidation {
                        _ = validationRule(newValue, fieldKey)
                    } else {
                        // Clear error for this field when skipping validation (during reset)
                        validationManager.errors.removeValue(forKey: fieldKey)
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
}

// MARK: - Validated Price Field
struct ValidatedPriceField: View {
    let title: String
    @Binding var price: Double
    let fieldKey: String
    @ObservedObject var validationManager: ValidationManager
    @State private var priceText: String = ""
    @State private var isUpdatingFromBinding = false
    
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
        self._priceText = State(initialValue: price.wrappedValue == 0.0 ? "" : String(format: "%.2f", price.wrappedValue))
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
                    .onChange(of: priceText) { oldValue, newValue in
                        // Skip processing if we're updating from the binding (to avoid infinite loop)
                        guard !isUpdatingFromBinding else { return }
                        
                        // Filter out non-numeric characters (except decimal point and comma)
                        let filtered = newValue.filter { $0.isNumber || $0 == "." || $0 == "," }
                        
                        // Replace comma with period for decimal separator
                        let withPeriod = filtered.replacingOccurrences(of: ",", with: ".")
                        
                        // Ensure only one decimal point
                        let components = withPeriod.components(separatedBy: ".")
                        let cleaned: String
                        if components.count > 2 {
                            // More than one decimal point - keep only the first
                            cleaned = components[0] + "." + components.dropFirst().joined().replacingOccurrences(of: ".", with: "")
                        } else {
                            cleaned = withPeriod
                        }
                        
                        // Limit to 2 decimal places
                        let finalValue: String
                        if let dotIndex = cleaned.firstIndex(of: ".") {
                            let integerPart = String(cleaned[..<dotIndex])
                            let decimalPart = String(cleaned[cleaned.index(after: dotIndex)...])
                            let limitedDecimal = String(decimalPart.prefix(2))
                            finalValue = integerPart + "." + limitedDecimal
                        } else {
                            finalValue = cleaned
                        }
                        
                        // Update the text if it changed (filtered invalid characters)
                        if priceText != finalValue {
                            isUpdatingFromBinding = true
                            priceText = finalValue
                            isUpdatingFromBinding = false
                        }
                        
                        // Parse and update price
                        if finalValue.isEmpty {
                            // Allow empty string (will be treated as 0)
                            price = 0.0
                            validationManager.errors.removeValue(forKey: fieldKey)
                        } else if let doubleValue = Double(finalValue) {
                            price = doubleValue
                            _ = validationManager.validatePrice(doubleValue, fieldKey: fieldKey)
                        }
                    }
                    .onChange(of: price) { oldValue, newValue in
                        // Skip if we're updating from text field (to avoid infinite loop)
                        guard !isUpdatingFromBinding else { return }
                        
                        // Sync priceText when price changes externally (e.g., form reset)
                        // Calculate what the priceText should be for this price value
                        let expectedText = newValue == 0.0 ? "" : String(format: "%.2f", newValue)
                        // Only update if different to avoid infinite loops
                        if priceText != expectedText {
                            isUpdatingFromBinding = true
                            priceText = expectedText
                            isUpdatingFromBinding = false
                            // Clear price error when resetting to 0
                            if newValue == 0.0 {
                                validationManager.errors.removeValue(forKey: fieldKey)
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
