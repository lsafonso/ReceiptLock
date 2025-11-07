//
//  BatchEditItemsSheet.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI

struct EditableItem: Identifiable {
    let id: UUID
    var title: String
    var price: Decimal?
    var warrantyMonths: Int
    var category: String
    var originalLineText: String
    var quantity: Int
}

struct BatchEditItemsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let items: [EditableItem]
    let onCreate: ([EditableItem]) -> Void
    
    @State private var editableItems: [EditableItem] = []
    
    private var hasValidItems: Bool {
        editableItems.contains { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.spacing) {
                        Text("Edit items")
                            .rlHeadline()
                            .padding(.horizontal, AppTheme.spacing)
                            .padding(.top, AppTheme.spacing)
                        
                        LazyVStack(spacing: AppTheme.spacing) {
                            ForEach($editableItems) { $item in
                                EditableItemRow(item: $item)
                            }
                        }
                        .padding(.horizontal, AppTheme.spacing)
                    }
                    .padding(.bottom, AppTheme.tabBarBottomPadding)
                }
                
                // Footer button
                VStack {
                    Spacer()
                    VStack(spacing: AppTheme.smallSpacing) {
                        Button(action: {
                            onCreate(editableItems)
                        }) {
                            Text("Create \(editableItems.count) Items")
                                .font(.headline.weight(.semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppTheme.spacing)
                                .background(hasValidItems ? AppTheme.primary : AppTheme.secondaryText)
                                .cornerRadius(AppTheme.cornerRadius)
                        }
                        .disabled(!hasValidItems)
                        .padding(.horizontal, AppTheme.spacing)
                    }
                    .padding(.vertical, AppTheme.spacing)
                    .background(AppTheme.card)
                    .cornerRadius(AppTheme.CornerRadius.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                            .strokeBorder(AppTheme.cardStroke, lineWidth: AppTheme.hairlineWidth)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 8, y: -2)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            editableItems = items
        }
    }
}

struct EditableItemRow: View {
    @Binding var item: EditableItem
    
    private let warrantyOptions = [12, 24, 36]
    @State private var customWarrantyMonths: String = ""
    @State private var showingCustomWarranty = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            // Title
            VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
                Text("Title")
                    .rlCaption()
                    .foregroundColor(AppTheme.secondaryText)
                TextField("Enter item name", text: $item.title)
                    .textFieldStyle(.plain)
                    .padding(AppTheme.smallSpacing)
                    .background(AppTheme.background)
                    .cornerRadius(AppTheme.smallCornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                            .stroke(AppTheme.separator, lineWidth: 1)
                    )
            }
            
            // Price
            VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
                Text("Price")
                    .rlCaption()
                    .foregroundColor(AppTheme.secondaryText)
                HStack {
                    Text(CurrencyManager.shared.currencySymbol)
                        .foregroundColor(AppTheme.secondaryText)
                    TextField("0.00", value: $item.price, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)
                }
                .padding(AppTheme.smallSpacing)
                .background(AppTheme.background)
                .cornerRadius(AppTheme.smallCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                        .stroke(AppTheme.separator, lineWidth: 1)
                )
            }
            
            // Warranty
            VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
                Text("Warranty (months)")
                    .rlCaption()
                    .foregroundColor(AppTheme.secondaryText)
                HStack(spacing: AppTheme.smallSpacing) {
                    ForEach(warrantyOptions, id: \.self) { months in
                        Button(action: {
                            item.warrantyMonths = months
                            showingCustomWarranty = false
                        }) {
                            Text("\(months)")
                                .font(.caption.weight(.medium))
                                .foregroundColor(item.warrantyMonths == months ? .white : AppTheme.text)
                                .padding(.horizontal, AppTheme.spacing)
                                .padding(.vertical, AppTheme.smallSpacing)
                                .background(item.warrantyMonths == months ? AppTheme.primary : AppTheme.background)
                                .cornerRadius(AppTheme.smallCornerRadius)
                        }
                    }
                    
                    Button(action: {
                        showingCustomWarranty.toggle()
                    }) {
                        Text("Other")
                            .font(.caption.weight(.medium))
                            .foregroundColor(showingCustomWarranty ? .white : AppTheme.text)
                            .padding(.horizontal, AppTheme.spacing)
                            .padding(.vertical, AppTheme.smallSpacing)
                            .background(showingCustomWarranty ? AppTheme.primary : AppTheme.background)
                            .cornerRadius(AppTheme.smallCornerRadius)
                    }
                    
                    if showingCustomWarranty {
                        TextField("Months", text: $customWarrantyMonths)
                            .keyboardType(.numberPad)
                            .frame(width: 80)
                            .padding(AppTheme.smallSpacing)
                            .background(AppTheme.background)
                            .cornerRadius(AppTheme.smallCornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                                    .stroke(AppTheme.separator, lineWidth: 1)
                            )
                            .onChange(of: customWarrantyMonths) { _, newValue in
                                if let months = Int(newValue) {
                                    item.warrantyMonths = months
                                }
                            }
                    }
                }
            }
            
            // Category (Device Type)
            VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
                Text("Category")
                    .rlCaption()
                    .foregroundColor(AppTheme.secondaryText)
                Picker("Category", selection: $item.category) {
                    Text("None").tag("")
                    ForEach(AddApplianceView.DeviceType.allCases, id: \.rawValue) { deviceType in
                        Text(deviceType.rawValue).tag(deviceType.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .padding(AppTheme.smallSpacing)
                .background(AppTheme.background)
                .cornerRadius(AppTheme.smallCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                        .stroke(AppTheme.separator, lineWidth: 1)
                )
            }
        }
        .padding(AppTheme.spacing)
        .background(AppTheme.card)
        .cornerRadius(AppTheme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
    }
}

#Preview {
    BatchEditItemsSheet(
        items: [
            EditableItem(
                id: UUID(),
                title: "Samsung Galaxy S24",
                price: 899.99,
                warrantyMonths: 12,
                category: "",
                originalLineText: "Samsung Galaxy S24",
                quantity: 1
            )
        ],
        onCreate: { _ in }
    )
}

