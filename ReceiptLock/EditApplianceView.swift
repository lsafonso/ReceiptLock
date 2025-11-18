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
    @State private var showingSaveToast = false
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
            ZStack(alignment: .bottom) {
                AppTheme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.largeSpacing) {
                        pageHeader
                        basicInformationSection
                        purchaseDetailsSection
                        warrantySection
                        notesSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, AppTheme.smallSpacing)
                    .padding(.bottom, AppTheme.tabBarBottomPadding)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
                
                if showingSaveToast {
                    SaveToastView(
                        title: "Saved",
                        message: "Appliance updated successfully"
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .allowsHitTesting(false)
                }
            }
            .toolbarRole(.editor)
            .navigationTitle("Edit Appliance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CancelButton(action: { dismiss() }, hasUnsavedChanges: hasUnsavedChanges)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    ToolbarSaveButton(
                        state: saveButtonState,
                        isDisabled: title.isEmpty || brand.isEmpty || saveButtonState == .loading || saveButtonState == .success,
                        action: saveChanges
                    )
                }
            }
            .animation(AppTheme.easeInOutAnimation, value: showingSaveToast)
        }
    }
    
    private var pageHeader: some View {
        Text("Edit Appliance")
            .font(.headline.weight(.semibold))
            .foregroundColor(AppTheme.text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, AppTheme.smallSpacing)
            .accessibilityAddTraits(.isHeader)
    }
    
    private var basicInformationSection: some View {
        SectionCard(title: "Basic Information") {
            FieldContainer(label: "Appliance Name") {
                TextField("Enter appliance name", text: $title)
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
            }
            
            FieldContainer(label: "Brand") {
                TextField("Enter brand", text: $brand)
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
            }
            
            FieldContainer(label: "Model") {
                TextField("Enter model", text: $model)
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
            }
            
            FieldContainer(label: "Serial Number") {
                TextField("Enter serial number", text: $serialNumber)
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.none)
                    .autocorrectionDisabled()
            }
        }
    }
    
    private var purchaseDetailsSection: some View {
        SectionCard(title: "Purchase Details") {
            TintedControlField(label: "Purchase Date") {
                DatePicker("", selection: $purchaseDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .accentColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            FieldContainer(label: "Price") {
                HStack(spacing: AppTheme.smallSpacing) {
                    Text(CurrencyManager.shared.currencySymbol)
                        .font(.body.weight(.semibold))
                        .foregroundColor(AppTheme.secondaryText)
                    PriceTextField(price: $price)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    private var warrantySection: some View {
        SectionCard(title: "Warranty") {
            WarrantyDurationField(value: $warrantyMonths)
            
            FieldContainer(label: "Warranty Summary") {
                TextField("Add a short warranty summary", text: $warrantySummary, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(3...6)
                    .frame(minHeight: 96, alignment: .topLeading)
                    .textInputAutocapitalization(.sentences)
            }
        }
    }
    
    private var notesSection: some View {
        SectionCard(title: "Additional Notes") {
            FieldContainer(label: "Notes") {
                TextField("Add any additional notes", text: $notes, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(3...6)
                    .frame(minHeight: 120, alignment: .topLeading)
                    .textInputAutocapitalization(.sentences)
            }
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
                // Auto-revert will happen after 0.8s, then show toast
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    self.showSaveConfirmationToast()
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

    private func showSaveConfirmationToast() {
        withAnimation(AppTheme.easeOutAnimation) {
            showingSaveToast = true
        }
        
        let toastDuration: TimeInterval = 2.5
        
        DispatchQueue.main.asyncAfter(deadline: .now() + toastDuration) {
            withAnimation(AppTheme.easeInOutAnimation) {
                showingSaveToast = false
            }
            dismiss()
        }
    }
}

// MARK: - UI Helpers

private struct SectionCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            content
        }
        .card()
    }
}

private struct FieldContainer<Content: View>: View {
    let label: String
    let content: Content
    
    init(label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
            Text(label)
                .font(.headline)
                .foregroundColor(AppTheme.text)
            
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppTheme.spacing)
                .padding(.vertical, AppTheme.smallSpacing)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.field, style: .continuous)
                        .fill(AppTheme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.field, style: .continuous)
                                .stroke(AppTheme.separator, lineWidth: AppTheme.hairlineWidth)
                        )
                )
        }
    }
}

private struct TintedControlField<Content: View>: View {
    let label: String
    let content: Content
    
    init(label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
            Text(label)
                .font(.headline)
                .foregroundColor(AppTheme.text)
            
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppTheme.smallSpacing)
                .padding(.vertical, AppTheme.smallSpacing / 2)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.field, style: .continuous)
                        .fill(AppTheme.primary)
                )
        }
    }
}

private struct WarrantyDurationField: View {
    @Binding var value: Int
    
    private var formattedValue: String {
        "\(value) " + (value == 1 ? "month" : "months")
    }
    
    init(value: Binding<Int>) {
        self._value = value
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
            Text("Duration (months)")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            HStack(alignment: .lastTextBaseline) {
                Text("Warranty Duration")
                    .font(.headline)
                    .foregroundColor(AppTheme.text)
                
                Spacer()
                
                Text(formattedValue)
                    .font(.headline)
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            Stepper("", value: $value, in: 1...60)
                .labelsHidden()
                .colorScheme(.dark)
                .accentColor(.white)
                .padding(.horizontal, AppTheme.smallSpacing)
                .padding(.vertical, AppTheme.smallSpacing / 2)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.field, style: .continuous)
                        .fill(AppTheme.primary)
                )
        }
    }
}

private struct ToolbarSaveButton: View {
    let state: SaveButtonState
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                switch state {
                case .loading:
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(AppTheme.primary)
                    Text("Saving")
                case .success:
                    Image(systemName: "checkmark")
                    Text("Saved")
                default:
                    Text("Save")
                }
            }
            .font(.headline.weight(.semibold))
            .foregroundColor(AppTheme.primary)
            .padding(.vertical, 8)
            .padding(.leading, 14)
            .padding(.trailing, 10)
            .frame(minHeight: 36)
            .background(
                Capsule()
                    .fill(AppTheme.primary.opacity(0.15))
            )
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.4 : 1.0)
        .animation(AppTheme.snappyAnimation, value: state)
    }
}

private struct SaveToastView: View {
    let title: String
    let message: String
    
    var body: some View {
        HStack(spacing: AppTheme.smallSpacing) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3.weight(.semibold))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline.weight(.semibold))
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.onPrimary.opacity(0.9))
            }
            
            Spacer()
        }
        .foregroundColor(AppTheme.onPrimary)
        .padding(.vertical, AppTheme.spacing)
        .padding(.horizontal, AppTheme.spacing)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                .fill(AppTheme.primary)
        )
        .shadow(color: AppTheme.primary.opacity(0.3), radius: 12, x: 0, y: 6)
        .accessibilityElement(children: .combine)
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
        TextField("0.00", text: $priceText)
            .textFieldStyle(.plain)
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
