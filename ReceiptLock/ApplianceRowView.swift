//
//  ApplianceRowView.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI

struct ApplianceRowView: View {
    let receipt: Receipt
    @State private var isPressed = false
    @State private var showPulse = false
    
    var body: some View {
        HStack(spacing: AppTheme.spacing) {
            // Appliance icon
            Image(systemName: getApplianceIcon())
                .font(.title2)
                .foregroundColor(getApplianceColor())
                .frame(width: 40, height: 40)
                .background(getApplianceColor().opacity(0.1))
                .cornerRadius(AppTheme.smallCornerRadius)
            
            // Appliance details
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(receipt.title ?? "Untitled Appliance")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(AppTheme.text)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Tag
                    Text("MOM")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.primary)
                        .cornerRadius(4)
                }
                
                HStack {
                    Text("Will expire on: \(formattedExpiryDate)")
                        .font(.caption.weight(.medium))
                        .foregroundColor(expiryStatusColor)
                    
                    Spacer()
                }
                
                // Progress bar
                ProgressView(value: progressValue, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: expiryStatusColor))
                    .frame(height: 4)
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
    
    private var formattedExpiryDate: String {
        guard let expiryDate = receipt.expiryDate else { return "Unknown" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        return formatter.string(from: expiryDate)
    }
    
    private var progressValue: Double {
        guard let purchaseDate = receipt.purchaseDate,
              let expiryDate = receipt.expiryDate else { return 0.0 }
        
        let now = Date()
        let totalDuration = expiryDate.timeIntervalSince(purchaseDate)
        let elapsedDuration = now.timeIntervalSince(purchaseDate)
        
        let progress = elapsedDuration / totalDuration
        return max(0.0, min(1.0, progress))
    }
    
    private var isUrgent: Bool {
        guard let expiryDate = receipt.expiryDate else { return false }
        
        let now = Date()
        let daysUntilExpiry = Calendar.current.dateComponents([.day], from: now, to: expiryDate).day ?? 0
        
        return expiryDate < now || daysUntilExpiry <= 7
    }
    
    // MARK: - Helper Methods
    
    private func getApplianceIcon() -> String {
        let title = receipt.title?.lowercased() ?? ""
        
        if title.contains("laptop") || title.contains("computer") {
            return "laptopcomputer"
        } else if title.contains("mobile") || title.contains("phone") {
            return "iphone"
        } else if title.contains("watch") {
            return "applewatch"
        } else if title.contains("tablet") || title.contains("ipad") {
            return "ipad"
        } else if title.contains("air") && title.contains("conditioner") {
            return "snowflake"
        } else if title.contains("refrigerator") || title.contains("fridge") {
            return "thermometer.snowflake"
        } else if title.contains("washing") || title.contains("washer") {
            return "washer"
        } else if title.contains("microwave") {
            return "microwave"
        } else if title.contains("television") || title.contains("tv") {
            return "tv"
        } else if title.contains("camera") {
            return "camera"
        } else if title.contains("speaker") || title.contains("audio") {
            return "speaker"
        } else if title.contains("headphone") {
            return "headphones"
        } else if title.contains("printer") {
            return "printer"
        } else if title.contains("monitor") || title.contains("display") {
            return "display"
        } else if title.contains("keyboard") {
            return "keyboard"
        } else {
            return "gearshape"
        }
    }
    
    private func getApplianceColor() -> Color {
        let title = receipt.title?.lowercased() ?? ""
        
        if title.contains("laptop") || title.contains("computer") || title.contains("mobile") || title.contains("phone") || title.contains("tablet") || title.contains("watch") {
            return .indigo
        } else if title.contains("air") && title.contains("conditioner") {
            return .blue
        } else if title.contains("refrigerator") || title.contains("fridge") {
            return .teal
        } else if title.contains("washing") || title.contains("washer") {
            return .cyan
        } else if title.contains("microwave") {
            return .brown
        } else if title.contains("television") || title.contains("tv") {
            return .mint
        } else if title.contains("camera") {
            return .gray
        } else if title.contains("speaker") || title.contains("audio") || title.contains("headphone") {
            return .purple
        } else if title.contains("printer") {
            return .black
        } else if title.contains("monitor") || title.contains("display") {
            return .mint
        } else if title.contains("keyboard") {
            return .gray
        } else {
            return AppTheme.primary
        }
    }
}
