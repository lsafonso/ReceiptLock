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
            Form {
                Section("Receipt Information") {
                    TextField("Title", text: $title)
                        .accessibilityLabel("Receipt title")
                    
                    TextField("Store", text: $store)
                        .accessibilityLabel("Store name")
                    
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                        .accessibilityLabel("Purchase date")
                    
                    HStack {
                        Text("Price")
                        Spacer()
                        TextField("0.00", value: $price, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Price amount")
                    }
                    
                    Stepper("Warranty: \(warrantyMonths) months", value: $warrantyMonths, in: 0...120)
                        .accessibilityLabel("Warranty duration in months")
                }
                
                if !warrantySummary.isEmpty {
                    Section("Warranty Summary") {
                        Text(warrantySummary)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveReceipt()
                    }
                    .disabled(title.isEmpty || store.isEmpty)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func saveReceipt() {
        receipt.title = title
        receipt.store = store
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
            dismiss()
        } catch {
            errorMessage = "Failed to save receipt: \(error.localizedDescription)"
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