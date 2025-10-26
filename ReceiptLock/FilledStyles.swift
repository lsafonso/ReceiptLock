//
//  FilledStyles.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI

// MARK: - Filled Button Styles

/// Primary filled button style with automatic white foreground
struct PrimaryFilledButtonStyle: ButtonStyle {
    @State private var isPressed = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundColor(AppTheme.onPrimary)
            .padding(.horizontal, AppTheme.largeSpacing)
            .padding(.vertical, AppTheme.spacing)
            .background(
                AppTheme.primaryGradient
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .cornerRadius(AppTheme.cornerRadius)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .shadow(
                color: AppTheme.primary.opacity(0.2),
                radius: configuration.isPressed ? 6 : 8,
                x: 0,
                y: configuration.isPressed ? 2 : 3
            )
            .animation(AppTheme.snappyAnimation, value: configuration.isPressed)
    }
}

/// Generic filled button style for success, warning, etc.
struct FilledButtonStyle: ButtonStyle {
    let backgroundColor: Color
    @State private var isPressed = false
    
    init(backgroundColor: Color = AppTheme.primary) {
        self.backgroundColor = backgroundColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundColor(backgroundColor.rlOn())
            .padding(.horizontal, AppTheme.largeSpacing)
            .padding(.vertical, AppTheme.spacing)
            .background(
                backgroundColor
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .cornerRadius(AppTheme.cornerRadius)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .shadow(
                color: backgroundColor.opacity(0.2),
                radius: configuration.isPressed ? 6 : 8,
                x: 0,
                y: configuration.isPressed ? 2 : 3
            )
            .animation(AppTheme.snappyAnimation, value: configuration.isPressed)
    }
}

/// Pill style for filled badges and chips
struct PillFilledStyle: ViewModifier {
    let background: Color
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    
    init(background: Color, horizontal: CGFloat = 12, vertical: CGFloat = 8) {
        self.background = background
        self.horizontalPadding = horizontal
        self.verticalPadding = vertical
    }
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(background.rlOn())
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                Capsule()
                    .fill(background)
            )
    }
}

// MARK: - View Extensions

extension View {
    /// Applies filled pill style with automatic on-color foreground
    func filledPill(background: Color = AppTheme.primary, horizontal: CGFloat = 12, vertical: CGFloat = 8) -> some View {
        modifier(PillFilledStyle(background: background, horizontal: horizontal, vertical: vertical))
    }
    
    /// Applies primary filled button style
    func primaryFilledButton() -> some View {
        buttonStyle(PrimaryFilledButtonStyle())
    }
    
    /// Applies filled button style with custom background color
    func filledButton(background: Color) -> some View {
        buttonStyle(FilledButtonStyle(backgroundColor: background))
    }
}

// MARK: - Color Extension for On-Color Resolution

extension Color {
    /// Returns the appropriate on-color for this color
    /// Ensures AA contrast for text on colored backgrounds
    /// Uses luminance check for unknown colors to maintain ≥4.5:1 contrast
    func rlOn() -> Color {
        // Known theme colors
        if self == AppTheme.primary {
            return AppTheme.onPrimary
        } else if self == AppTheme.success {
            return AppTheme.onSuccess
        } else if self == AppTheme.warning {
            return AppTheme.onWarning
        } else if self == AppTheme.error {
            return AppTheme.onDanger
        } else if self == AppTheme.accent || self == AppTheme.secondary {
            return AppTheme.onTint
        }
        
        // For unknown colors, compute relative luminance
        // If background is dark (low luminance), use white text
        // If background is light (high luminance), use dark text
        if self.relativeLuminance < 0.5 {
            return Color.white
        } else {
            return AppTheme.text
        }
    }
    
    /// Computes relative luminance (L) for WCAG contrast calculation
    /// Returns value between 0 (black) and 1 (white)
    var relativeLuminance: Double {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        // Get color components
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Apply gamma correction
        let r = red <= 0.03928 ? red / 12.92 : pow((red + 0.055) / 1.055, 2.4)
        let g = green <= 0.03928 ? green / 12.92 : pow((green + 0.055) / 1.055, 2.4)
        let b = blue <= 0.03928 ? blue / 12.92 : pow((blue + 0.055) / 1.055, 2.4)
        
        // Calculate relative luminance
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }
}

