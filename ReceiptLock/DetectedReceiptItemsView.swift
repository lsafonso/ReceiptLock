//
//  DetectedReceiptItemsView.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI

struct DetectedReceiptItemsView: View {
    @Environment(\.dismiss) private var dismiss
    let lines: [AddApplianceView.DetectedLine]
    let onContinue: ([AddApplianceView.DetectedLine]) -> Void
    
    @State private var selectedLineIds: Set<UUID> = []
    @State private var showingBatchEdit = false
    @State private var editableItems: [EditableItem] = []
    @State private var lineQuantities: [UUID: Int] = [:]
    @State private var showLowConfidence = false
    
    // Separate high confidence (score >= 1.0) and low confidence (0 <= score < 1.0) items
    private var highConfidenceLines: [AddApplianceView.DetectedLine] {
        lines.filter { $0.score >= 1.0 }
    }
    
    private var lowConfidenceLines: [AddApplianceView.DetectedLine] {
        lines.filter { $0.score >= 0.0 && $0.score < 1.0 }
    }
    
    private var selectedLines: [AddApplianceView.DetectedLine] {
        lines.filter { selectedLineIds.contains($0.id) }.map { line in
            var updatedLine = line
            updatedLine.quantity = lineQuantities[line.id] ?? line.quantity
            return updatedLine
        }
    }
    
    // Check if we should show the "too many items" warning
    private var shouldShowTooManyWarning: Bool {
        lines.count > 20
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()
                
                if lines.isEmpty {
                    emptyStateView
                } else {
                    VStack(spacing: 0) {
                        ScrollView {
                            VStack(alignment: .leading, spacing: AppTheme.spacing) {
                                Text("Detected items")
                                    .rlHeadline()
                                    .padding(.horizontal, AppTheme.spacing)
                                    .padding(.top, AppTheme.spacing)
                                
                                // Warning banner if too many items
                                if shouldShowTooManyWarning {
                                    HStack {
                                        Image(systemName: "info.circle.fill")
                                            .foregroundColor(AppTheme.primary)
                                        Text("We found many numbers on this receipt. Select only the products you bought.")
                                            .rlBody()
                                            .foregroundColor(AppTheme.text)
                                    }
                                    .padding(AppTheme.spacing)
                                    .background(AppTheme.card)
                                    .cornerRadius(AppTheme.cornerRadius)
                                    .padding(.horizontal, AppTheme.spacing)
                                }
                                
                                // High confidence items (always shown)
                                if !highConfidenceLines.isEmpty {
                                    LazyVStack(spacing: AppTheme.smallSpacing) {
                                        ForEach(highConfidenceLines) { line in
                                            DetectedLineRow(
                                                line: line,
                                                isSelected: selectedLineIds.contains(line.id),
                                                quantity: Binding(
                                                    get: { lineQuantities[line.id] ?? line.quantity },
                                                    set: { lineQuantities[line.id] = $0 }
                                                ),
                                                onToggle: {
                                                    if selectedLineIds.contains(line.id) {
                                                        selectedLineIds.remove(line.id)
                                                    } else {
                                                        selectedLineIds.insert(line.id)
                                                    }
                                                }
                                            )
                                        }
                                    }
                                    .padding(.horizontal, AppTheme.spacing)
                                }
                                
                                // Low confidence items (collapsible)
                                if !lowConfidenceLines.isEmpty {
                                    VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
                                        Button(action: {
                                            showLowConfidence.toggle()
                                        }) {
                                            HStack {
                                                Text("Show low-confidence items (\(lowConfidenceLines.count))")
                                                    .rlBody()
                                                    .foregroundColor(AppTheme.primary)
                                                Spacer()
                                                Image(systemName: showLowConfidence ? "chevron.down" : "chevron.right")
                                                    .foregroundColor(AppTheme.primary)
                                                    .font(.caption)
                                            }
                                            .padding(.horizontal, AppTheme.spacing)
                                            .padding(.vertical, AppTheme.smallSpacing)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        if showLowConfidence {
                                            LazyVStack(spacing: AppTheme.smallSpacing) {
                                                ForEach(lowConfidenceLines) { line in
                                                    DetectedLineRow(
                                                        line: line,
                                                        isSelected: selectedLineIds.contains(line.id),
                                                        quantity: Binding(
                                                            get: { lineQuantities[line.id] ?? line.quantity },
                                                            set: { lineQuantities[line.id] = $0 }
                                                        ),
                                                        onToggle: {
                                                            if selectedLineIds.contains(line.id) {
                                                                selectedLineIds.remove(line.id)
                                                            } else {
                                                                selectedLineIds.insert(line.id)
                                                            }
                                                        }
                                                    )
                                                }
                                            }
                                            .padding(.horizontal, AppTheme.spacing)
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, AppTheme.tabBarBottomPadding)
                        }
                        
                        // Footer with Continue button
                        VStack(spacing: AppTheme.smallSpacing) {
                            if !selectedLines.isEmpty {
                                Button(action: {
                                    prepareBatchEdit()
                                }) {
                                    Text("Continue (\(selectedLines.count))")
                                        .font(.headline.weight(.semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, AppTheme.spacing)
                                        .background(AppTheme.primary)
                                        .cornerRadius(AppTheme.cornerRadius)
                                }
                                .padding(.horizontal, AppTheme.spacing)
                            }
                        }
                        .padding(.vertical, AppTheme.spacing)
                        .background(AppTheme.card)
                        .shadow(color: .black.opacity(0.05), radius: 8, y: -2)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if !lines.isEmpty {
                        Button(selectedLineIds.count == highConfidenceLines.count ? "Deselect All" : "Select All") {
                            if selectedLineIds.count == highConfidenceLines.count {
                                selectedLineIds.removeAll()
                            } else {
                                // Select all high confidence items
                                selectedLineIds = Set(highConfidenceLines.map { $0.id })
                            }
                        }
                    }
                }
            }
            .onAppear {
                // Default selection: pre-select only high confidence items (score >= 1.0)
                // But if >20 items, auto-select none and show warning
                if shouldShowTooManyWarning {
                    // Don't auto-select if too many items
                    selectedLineIds = []
                } else {
                    // Pre-select high confidence items (score >= 1.0)
                    // Cap to top 15 by score (already done in parseDetectedLines, but ensure here)
                    let sortedHighConfidence = highConfidenceLines.sorted { $0.score > $1.score }
                    let topItems = Array(sortedHighConfidence.prefix(15))
                    selectedLineIds = Set(topItems.map { $0.id })
                }
                
                // Initialize quantities
                for line in lines {
                    lineQuantities[line.id] = line.quantity
                }
            }
            .sheet(isPresented: $showingBatchEdit) {
                BatchEditItemsSheet(
                    items: editableItems,
                    onCreate: { items in
                        onContinue(convertEditableItemsToLines(items))
                        dismiss()
                    }
                )
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.largeSpacing) {
            Spacer()
            
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 72, weight: .light))
                .foregroundColor(AppTheme.secondaryText)
            
            VStack(spacing: AppTheme.smallSpacing) {
                Text("We couldn't confidently detect line items")
                    .rlTitle2()
                    .multilineTextAlignment(.center)
                
                Text("You can add this device manually.")
                    .rlBodyMuted()
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, AppTheme.largeSpacing)
            
            Spacer()
        }
    }
    
    private func prepareBatchEdit() {
        editableItems = selectedLines.map { line in
            EditableItem(
                id: line.id,
                title: line.text,
                price: line.amount,
                warrantyMonths: 12,
                category: "",
                originalLineText: line.text,
                quantity: line.quantity
            )
        }
        showingBatchEdit = true
    }
    
    private func convertEditableItemsToLines(_ items: [EditableItem]) -> [AddApplianceView.DetectedLine] {
        var result: [AddApplianceView.DetectedLine] = []
        for item in items {
            for _ in 0..<item.quantity {
                result.append(AddApplianceView.DetectedLine(
                    text: item.originalLineText,
                    amount: item.price,
                    quantity: 1
                ))
            }
        }
        return result
    }
    
    private func hasModelLikeToken(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        let modelTokens = ["model", "mod", "serial", "sn", "sku", "item", "product"]
        return modelTokens.contains { lowercased.contains($0) }
    }
}

struct DetectedLineRow: View {
    let line: AddApplianceView.DetectedLine
    let isSelected: Bool
    @Binding var quantity: Int
    let onToggle: () -> Void
    
    // Confidence indicator color based on score
    private var confidenceColor: Color {
        if line.score >= 1.8 {
            return .green
        } else if line.score >= 1.0 {
            return .orange
        } else {
            return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: AppTheme.spacing) {
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? AppTheme.primary : AppTheme.secondaryText)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
                HStack(spacing: AppTheme.smallSpacing) {
                    // Confidence dot
                    Circle()
                        .fill(confidenceColor)
                        .frame(width: 8, height: 8)
                    
                    Text(line.text)
                        .rlBody()
                        .foregroundColor(AppTheme.text)
                }
                
                if let amount = line.amount {
                    Text(CurrencyManager.shared.formatPrice(NSDecimalNumber(decimal: amount).doubleValue))
                        .rlCaption()
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
            
            Spacer()
            
            // Show quantity stepper if line contains quantity indicators or if selected
            if isSelected && (line.text.contains("x") || line.text.contains("×") || line.text.contains("X") || quantity > 1) {
                Stepper(value: $quantity, in: 1...99) {
                    Text("Qty: \(quantity)")
                        .rlCaption()
                        .foregroundColor(AppTheme.secondaryText)
                }
                .frame(width: 100)
            }
        }
        .padding(AppTheme.spacing)
        .background(AppTheme.card)
        .cornerRadius(AppTheme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(isSelected ? AppTheme.primary : AppTheme.separator, lineWidth: isSelected ? 2 : 1)
        )
    }
}

#Preview {
    DetectedReceiptItemsView(
        lines: [
            AddApplianceView.DetectedLine(text: "Samsung Galaxy S24", amount: 899.99, quantity: 1, score: 2.5),
            AddApplianceView.DetectedLine(text: "iPhone 15 Pro x2", amount: 1299.00, quantity: 2, score: 2.8),
            AddApplianceView.DetectedLine(text: "AirPods Pro", amount: 249.99, quantity: 1, score: 2.0),
            AddApplianceView.DetectedLine(text: "Low confidence item", amount: nil, quantity: 1, score: 0.5)
        ],
        onContinue: { _ in }
    )
}

