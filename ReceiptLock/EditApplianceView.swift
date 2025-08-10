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
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(title.isEmpty || brand.isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() {
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
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving changes: \(error)")
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
