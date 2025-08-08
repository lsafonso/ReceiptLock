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
            return "Price cannot exceed $999,999"
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
    
    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        fieldKey: String,
        validationManager: ValidationManager,
        validationRule: @escaping (String, String) -> Bool
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
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
            }
            
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
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
                .onChange(of: text) { _, newValue in
                    _ = validationRule(newValue, fieldKey)
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
        self._priceText = State(initialValue: String(format: "%.2f", price.wrappedValue))
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
                Text("$")
                    .font(.body)
                    .foregroundColor(AppTheme.secondaryText)
                
                TextField("0.00", text: $priceText)
                    .keyboardType(.decimalPad)
                    .onChange(of: priceText) { _, newValue in
                        if let doubleValue = Double(newValue) {
                            price = doubleValue
                            _ = validationManager.validatePrice(doubleValue, fieldKey: fieldKey)
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
            
            Stepper("", value: $value, in: range)
                .labelsHidden()
                .onChange(of: value) { _, newValue in
                    _ = validationRule(newValue, fieldKey)
                }
        }
        .padding()
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
            
            DatePicker(
                "",
                selection: $date,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .onChange(of: date) { _, newValue in
                _ = validationManager.validatePurchaseDate(newValue, fieldKey: fieldKey)
            }
        }
        .padding()
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
