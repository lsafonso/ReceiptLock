//
//  ReceiptRowView.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI

struct ReceiptRowView: View {
    let receipt: Receipt
    @State private var isPressed = false
    @State private var showPulse = false
    
    var body: some View {
        HStack(spacing: AppTheme.spacing) {
            // Receipt thumbnail image
            if let imageData = receipt.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.secondaryBackground)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "doc.text")
                            .font(.title2)
                            .foregroundColor(AppTheme.secondaryText)
                    )
            }
            
            // Status indicator with pulse animation
            ZStack {
                if showPulse {
                    PulseAnimation(color: expiryStatusColor)
                        .frame(width: 20, height: 20)
                }
                
                Circle()
                    .fill(expiryStatusColor)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(expiryStatusColor.opacity(0.3), lineWidth: 2)
                            .frame(width: 16, height: 16)
                    )
            }
            
            // Receipt details
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(receipt.title ?? "Untitled Receipt")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(AppTheme.text)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(receipt.price, format: .currency(code: CurrencyManager.shared.currencyCode))
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(AppTheme.primary)
                        .contentTransition(.numericText())
                }
                
                HStack {
                    Text(receipt.store ?? "Unknown Store")
                        .font(.caption.weight(.medium))
                        .foregroundColor(AppTheme.secondaryText)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: expiryStatusIcon)
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(expiryStatusColor)
                        
                        Text(expiryStatusText)
                            .font(.caption.weight(.medium))
                            .foregroundColor(expiryStatusColor)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(expiryStatusColor.opacity(0.1))
                    )
                }
            }
            
            // Chevron with animation
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(AppTheme.secondaryText)
                .rotationEffect(.degrees(isPressed ? 90 : 0))
                .animation(AppTheme.springAnimation, value: isPressed)
        }
        .padding(AppTheme.spacing)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(
            color: .black.opacity(AppTheme.shadowOpacity),
            radius: isPressed ? AppTheme.shadowRadius * 0.7 : AppTheme.shadowRadius,
            x: AppTheme.shadowOffset.width,
            y: isPressed ? AppTheme.shadowOffset.height * 0.7 : AppTheme.shadowOffset.height
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(AppTheme.springAnimation, value: isPressed)
        .onTapGesture {
            withAnimation(AppTheme.springAnimation) {
                isPressed = true
            }
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            // Show pulse for urgent items
            if isUrgent {
                showPulse = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showPulse = false
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(AppTheme.springAnimation) {
                    isPressed = false
                }
            }
        }
        .onAppear {
            // Show pulse animation for urgent items on appear
            if isUrgent {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showPulse = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        showPulse = false
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var expiryStatusColor: Color {
        guard let expiryDate = receipt.expiryDate else { return AppTheme.secondaryText }
        
        let now = Date()
        let daysUntilExpiry = Calendar.current.dateComponents([.day], from: now, to: expiryDate).day ?? 0
        
        if expiryDate < now {
            return AppTheme.error
        } else if daysUntilExpiry <= 7 {
            return AppTheme.error
        } else if daysUntilExpiry <= 30 {
            return AppTheme.warning
        } else {
            return AppTheme.success
        }
    }
    
    private var expiryStatusIcon: String {
        guard let expiryDate = receipt.expiryDate else { return "questionmark.circle" }
        
        let now = Date()
        let daysUntilExpiry = Calendar.current.dateComponents([.day], from: now, to: expiryDate).day ?? 0
        
        if expiryDate < now {
            return "exclamationmark.triangle.fill"
        } else if daysUntilExpiry <= 7 {
            return "exclamationmark.circle.fill"
        } else if daysUntilExpiry <= 30 {
            return "clock.fill"
        } else {
            return "checkmark.circle.fill"
        }
    }
    
    private var expiryStatusText: String {
        guard let expiryDate = receipt.expiryDate else { return "Unknown" }
        
        let now = Date()
        let daysUntilExpiry = Calendar.current.dateComponents([.day], from: now, to: expiryDate).day ?? 0
        
        if expiryDate < now {
            return "Expired"
        } else if daysUntilExpiry == 0 {
            return "Expires today"
        } else if daysUntilExpiry == 1 {
            return "Expires tomorrow"
        } else if daysUntilExpiry <= 7 {
            return "\(daysUntilExpiry) days"
        } else if daysUntilExpiry <= 30 {
            return "\(daysUntilExpiry) days"
        } else {
            return "Valid"
        }
    }
    
    private var isUrgent: Bool {
        guard let expiryDate = receipt.expiryDate else { return false }
        
        let now = Date()
        let daysUntilExpiry = Calendar.current.dateComponents([.day], from: now, to: expiryDate).day ?? 0
        
        return expiryDate < now || daysUntilExpiry <= 7
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
    
    return ReceiptRowView(receipt: receipt)
        .padding()
} 