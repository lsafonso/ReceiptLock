//
//  AppTheme.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI

// MARK: - App Theme
struct AppTheme {
    // MARK: - Colors (Updated to use muted green as primary)
    static let primary = Color(red: 51/255, green: 102/255, blue: 102/255) // Muted green as primary
    static let secondary = Color(red: 102/255, green: 204/255, blue: 153/255) // Light green for secondary actions
    static let accent = Color(red: 102/255, green: 204/255, blue: 153/255) // Light green for success states
    static let background = Color(red: 242/255, green: 244/255, blue: 246/255) // #F2F4F6
    static let cardBackground = Color.white
    static let secondaryBackground = Color(red: 245/255, green: 245/255, blue: 245/255)
    static let text = Color(red: 26/255, green: 26/255, blue: 26/255) // Dark text
    static let secondaryText = Color(red: 102/255, green: 102/255, blue: 102/255) // Light gray text
    static let error = Color(red: 192/255, green: 101/255, blue: 111/255) // Muted red for expired warranties
    static let warning = Color(red: 230/255, green: 154/255, blue: 100/255) // Muted orange for expiring warranties
    static let success = Color(red: 107/255, green: 183/255, blue: 124/255) // Muted green for valid warranties
    static let border = Color(red: 200/255, green: 200/255, blue: 200/255) // Light gray for borders
    static let separator = Color(red: 230/255, green: 233/255, blue: 237/255) // #E6E9ED separator color
    static let inactiveTabColor = Color(red: 122/255, green: 132/255, blue: 140/255) // #7A848C inactive tab color
    static let paginationInactive = Color(red: 215/255, green: 219/255, blue: 223/255) // #D7DBDF pagination inactive dots
    
    // MARK: - Card Stroke
    // Subtle border for section cards to improve separation after radius reduction
    // Light mode: ~12-14% opacity, Dark mode: ~22-26% opacity for better contrast
    // Uses UIColor to properly support light/dark mode
    static var cardStroke: Color {
        Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor.label.withAlphaComponent(0.24) // Dark mode: 24% opacity
            } else {
                return UIColor.label.withAlphaComponent(0.13) // Light mode: 13% opacity
            }
        })
    }
    
    // MARK: - On-Color Roles (Text on colored backgrounds for AA contrast)
    static let onPrimary = Color.white // Text on primary background
    static let onSuccess = Color.white // Text on success background
    static let onWarning = Color.white // Text on warning background
    static let onDanger = Color.white // Text on error/danger background
    static let onTint = Color.white // Text on tinted/accent background
    
    // MARK: - Gradients
    static let primaryGradient = LinearGradient(
        colors: [primary, primary.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardGradient = LinearGradient(
        colors: [cardBackground, cardBackground],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let softGradient = LinearGradient(
        colors: [background, background.opacity(0.8)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Spacing
    static let spacing: CGFloat = 16
    static let smallSpacing: CGFloat = 8
    static let largeSpacing: CGFloat = 24
    static let extraLargeSpacing: CGFloat = 32
    
    // MARK: - Corner Radius
    // Centralized corner radius tokens for consistent design scale
    // Reduced from previous values for a cleaner, tighter look
    enum CornerRadius {
        static let card: CGFloat = 14      // Cards/containers (white panels)
        static let tile: CGFloat = 12      // Home/scan grid buttons, device tiles
        static let field: CGFloat = 10     // Text fields, pickers, date button
        static let button: CGFloat = 12     // Primary/secondary CTA buttons
        static let chip: CGFloat = 10      // Pills/chips (fallback when Capsule not used)
        static let badge: CGFloat = 8       // Small tags/badges
    }
    
    // Legacy constants (deprecated - use CornerRadius enum instead)
    static let cornerRadius: CGFloat = CornerRadius.card
    static let smallCornerRadius: CGFloat = CornerRadius.badge
    static let largeCornerRadius: CGFloat = CornerRadius.card
    static let extraLargeCornerRadius: CGFloat = 20
    
    // MARK: - Card Tokens
    static let card = Color.white // #FFFFFF
    static let cardRadius: CGFloat = CornerRadius.card
    static let cardPadding: CGFloat = 16
    
    // MARK: - Tab Bar Constants
    static let tabBarHeight: CGFloat = 51 // 50pt content + 1pt separator
    static let tabBarBottomPadding: CGFloat = 58 // Tab bar height (51) + 8px breathing room
    
    // MARK: - Shadows
    static let shadowRadius: CGFloat = 8
    static let shadowOpacity: Double = 0.08
    static let shadowOffset = CGSize(width: 0, height: 2)
    
    // MARK: - Stroke Helpers
    // Hairline width for 1-px borders (scales with device pixel density)
    static var hairlineWidth: CGFloat {
        1.0 / (UIScreen.main.scale > 0 ? UIScreen.main.scale : 1.0)
    }
    
    // MARK: - Animations
    static let springAnimation = Animation.spring(response: 0.5, dampingFraction: 0.9, blendDuration: 0) // Less bouncy
    static let easeOutAnimation = Animation.easeOut(duration: 0.3)
    static let easeInOutAnimation = Animation.easeInOut(duration: 0.4)
    static let snappyAnimation = Animation.snappy(duration: 0.2) // For micro-interactions
}

// MARK: - Settings Metrics (single source of truth from header)
enum SettingsMetrics {
    // Section/card horizontal padding (use the SAME as card padding on the section)
    static let cardH: CGFloat = AppTheme.cardPadding
    // Section header icon size (SAME as header's icon frame)
    static let headerIcon: CGFloat = 36
    // Spacing between header icon and title (SAME as header gap)
    static let headerGap: CGFloat = 12
    // X where section title starts (relative to card's left edge)
    static var textLeading: CGFloat { cardH + headerIcon + headerGap }
    // Row icon size and gap (current)
    static let rowIcon: CGFloat = 24
    static let rowGap: CGFloat = 12
}

// MARK: - Custom View Modifiers
struct CardBackgroundModifier: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                    .strokeBorder(AppTheme.cardStroke, lineWidth: AppTheme.hairlineWidth)
            )
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(AppTheme.springAnimation) {
                        isPressed = false
                    }
                }
            }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
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
            .cornerRadius(AppTheme.CornerRadius.button)
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

struct SecondaryButtonStyle: ButtonStyle {
    @State private var isPressed = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundColor(AppTheme.primary)
            .padding(.horizontal, AppTheme.largeSpacing)
            .padding(.vertical, AppTheme.spacing)
            .background(
                AppTheme.primary.opacity(0.1)
            )
            .cornerRadius(AppTheme.CornerRadius.button)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(AppTheme.springAnimation, value: configuration.isPressed)
    }
}

struct FloatingActionButtonStyle: ButtonStyle {
    @State private var isPressed = false
    let backgroundColor: Color
    
    init(backgroundColor: Color = AppTheme.primary) {
        self.backgroundColor = backgroundColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2.weight(.semibold))
            .foregroundColor(backgroundColor.rlOn())
            .frame(width: 56, height: 56)
            .background(
                backgroundColor
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .clipShape(Circle())
            .shadow(
                color: backgroundColor.opacity(0.3),
                radius: configuration.isPressed ? 8 : 12,
                x: 0,
                y: configuration.isPressed ? 3 : 6
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(AppTheme.springAnimation, value: configuration.isPressed)
    }
}

// MARK: - Card Modifier
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.cardPadding)
            .background(AppTheme.card)
            .cornerRadius(AppTheme.CornerRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                    .strokeBorder(AppTheme.cardStroke, lineWidth: AppTheme.hairlineWidth)
            )
            .shadow(
                color: .black.opacity(AppTheme.shadowOpacity),
                radius: AppTheme.shadowRadius,
                x: AppTheme.shadowOffset.width,
                y: AppTheme.shadowOffset.height
            )
    }
}

// MARK: - View Extensions
extension View {
    func cardBackground() -> some View {
        modifier(CardBackgroundModifier())
    }
    
    func card() -> some View {
        modifier(CardModifier())
    }
    
    func primaryButton() -> some View {
        buttonStyle(PrimaryButtonStyle())
    }
    
    func secondaryButton() -> some View {
        buttonStyle(SecondaryButtonStyle())
    }
    
    func floatingActionButton() -> some View {
        buttonStyle(FloatingActionButtonStyle())
    }
    
    func floatingActionButton(backgroundColor: Color) -> some View {
        buttonStyle(FloatingActionButtonStyle(backgroundColor: backgroundColor))
    }
    
    func slideInTransition() -> some View {
        self.transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    func scaleTransition() -> some View {
        self.transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Interactive Components
struct AnimatedCounter: View {
    let value: Int
    let title: String
    let color: Color
    @State private var animatedValue: Int = 0
    
    var body: some View {
        VStack(spacing: AppTheme.smallSpacing) {
            Text("\(animatedValue)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .contentTransition(.numericText())
            
            Text(title)
                .rlCaption()
                .fontWeight(.medium)
                .foregroundColor(AppTheme.secondaryText)
        }
        .onAppear {
            withAnimation(AppTheme.springAnimation.delay(0.2)) {
                animatedValue = value
            }
        }
        .onChange(of: value) { _, newValue in
            withAnimation(AppTheme.springAnimation) {
                animatedValue = newValue
            }
        }
    }
}

struct PulseAnimation: View {
    @State private var isAnimating = false
    let color: Color
    
    var body: some View {
        Circle()
            .fill(color)
            .scaleEffect(isAnimating ? 1.2 : 1.0)
            .opacity(isAnimating ? 0.5 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    let actionTitle: String?
    let action: (() -> Void)?
    @State private var isAnimating = false
    
    init(
        title: String,
        message: String,
        systemImage: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: AppTheme.largeSpacing) {
            Spacer()
            
            Image(systemName: systemImage)
                .font(.system(size: 72, weight: .light)) // Icon 72pt
                .foregroundColor(AppTheme.secondaryText)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
                .accessibilityHidden(true)
                .onAppear {
                    isAnimating = true
                }
            
            VStack(spacing: 0) {
                Text(title)
                    .rlTitle2()
                    .multilineTextAlignment(.center)
                    .padding(.top, 16) // Icon→title 16pt
                
                Text(message)
                    .rlBodyMuted()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.largeSpacing)
                    .padding(.top, 8) // Title→message 8pt
            }
            .slideInTransition()
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack(spacing: AppTheme.smallSpacing) {
                        Image(systemName: "plus.circle.fill")
                        Text(actionTitle)
                    }
                }
                .padding(.top, 16) // Message→action 16pt
                .buttonStyle(PrimaryButtonStyle())
                .scaleTransition()
            }
            
            Spacer()
        }
        .padding(AppTheme.largeSpacing)
    }
}
