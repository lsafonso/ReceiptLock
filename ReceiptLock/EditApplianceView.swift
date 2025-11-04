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
                    
                    TextField("Price", value: $price, format: .currency(code: CurrencyManager.shared.currencyCode))
                        .keyboardType(.decimalPad)
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
