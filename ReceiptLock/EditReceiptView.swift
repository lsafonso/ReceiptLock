//
//  EditReceiptView.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI
import CoreData

struct EditReceiptView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let receipt: Receipt
    
    @State private var title: String
    @State private var store: String
    @State private var purchaseDate: Date
    @State private var price: Double
    @State private var warrantyMonths: Int
    @State private var warrantySummary: String
    @State private var showingError = false
    @State private var errorMessage = ""
    @StateObject private var validationManager = ValidationManager()
    @State private var showingValidationAlert = false
    
    init(receipt: Receipt) {
        self.receipt = receipt
        self._title = State(initialValue: receipt.title ?? "")
        self._store = State(initialValue: receipt.store ?? "")
        self._purchaseDate = State(initialValue: receipt.purchaseDate ?? Date())
        self._price = State(initialValue: receipt.price)
        self._warrantyMonths = State(initialValue: Int(receipt.warrantyMonths))
        self._warrantySummary = State(initialValue: receipt.warrantySummary ?? "")
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.largeSpacing) {
                    // Validation Error Banner
                    ValidationErrorBanner(validationManager: validationManager)
                        .animation(.easeInOut, value: validationManager.hasErrors())
                    
                    // Form Fields
                    VStack(spacing: AppTheme.spacing) {
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
                        
                        // Store/Brand Field
                        ValidatedTextField(
                            title: "Store/Brand",
                            placeholder: "Enter store or brand",
                            text: $store,
                            fieldKey: "store",
                            validationManager: validationManager
                        ) { value, fieldKey in
                            validationManager.validateRequired(value, fieldName: "Store name", fieldKey: fieldKey) &&
                            validationManager.validateStoreName(value, fieldKey: fieldKey)
                        }
                        
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
                    }
                    .padding(AppTheme.spacing)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(AppTheme.cornerRadius)
                    
                    // Warranty Summary Section
                    if !warrantySummary.isEmpty {
                        VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
                            Text("Warranty Summary")
                                .font(.headline)
                                .foregroundColor(AppTheme.text)
                            
                            Text(warrantySummary)
                                .font(.body)
                                .foregroundColor(AppTheme.secondaryText)
                                .padding()
                                .background(AppTheme.cardBackground)
                                .cornerRadius(AppTheme.cornerRadius)
                        }
                        .padding(AppTheme.spacing)
                        .background(AppTheme.cardBackground)
                        .cornerRadius(AppTheme.cornerRadius)
                    }
                }
                .padding(AppTheme.spacing)
            }
            .background(AppTheme.background)
            .navigationTitle("Edit Appliance")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveReceipt()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .alert("Validation Errors", isPresented: $showingValidationAlert) {
                Button("OK") {
                    validationManager.clearErrors()
                }
            } message: {
                Text("Please fix the validation errors before saving.")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func saveReceipt() {
        // Validate all fields before saving
        let isValid = validationManager.validateApplianceForm(
            title: title,
            store: store,
            price: price,
            warrantyMonths: warrantyMonths,
            purchaseDate: purchaseDate
        )
        
        if !isValid {
            showingValidationAlert = true
            
            // Haptic feedback for validation errors
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            return
        }
        
        receipt.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        receipt.store = store.trimmingCharacters(in: .whitespacesAndNewlines)
        receipt.purchaseDate = purchaseDate
        receipt.price = price
        receipt.warrantyMonths = Int16(warrantyMonths)
        receipt.warrantySummary = warrantySummary
        receipt.updatedAt = Date()
        
        // Calculate expiry date
        if warrantyMonths > 0 {
            receipt.expiryDate = Calendar.current.date(byAdding: .month, value: warrantyMonths, to: purchaseDate)
        } else {
            receipt.expiryDate = nil
        }
        
        do {
            try viewContext.save()
            
            // Update notification for warranty expiry
            NotificationManager.shared.cancelNotification(for: receipt)
            NotificationManager.shared.scheduleNotification(for: receipt)
            
            // Haptic feedback for successful save
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            dismiss()
        } catch {
            errorMessage = "Failed to save appliance: \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let receipt = Receipt(context: context)
    receipt.id = UUID()
    receipt.title = "iPhone 15 Pro"
    receipt.store = "Apple Store"
    receipt.price = 999.99
    receipt.purchaseDate = Date()
    receipt.warrantyMonths = 12
    receipt.expiryDate = Calendar.current.date(byAdding: .month, value: 12, to: Date())
    
    return EditReceiptView(receipt: receipt)
        .environment(\.managedObjectContext, context)
} 