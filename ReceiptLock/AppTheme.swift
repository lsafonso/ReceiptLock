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
    static let background = Color(red: 250/255, green: 245/255, blue: 240/255) // Soft beige background
    static let cardBackground = Color.white
    static let secondaryBackground = Color(red: 245/255, green: 245/255, blue: 245/255)
    static let text = Color(red: 26/255, green: 26/255, blue: 26/255) // Dark text
    static let secondaryText = Color(red: 102/255, green: 102/255, blue: 102/255) // Light gray text
    static let error = Color(red: 220/255, green: 53/255, blue: 69/255) // Red for expired warranties
    static let warning = Color(red: 255/255, green: 149/255, blue: 0/255) // Orange for expiring warranties
    static let success = Color(red: 52/255, green: 199/255, blue: 89/255) // Green for valid warranties
    
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
    static let cornerRadius: CGFloat = 12
    static let smallCornerRadius: CGFloat = 8
    static let largeCornerRadius: CGFloat = 16
    static let extraLargeCornerRadius: CGFloat = 20
    
    // MARK: - Shadows
    static let shadowRadius: CGFloat = 8
    static let shadowOpacity: Double = 0.08
    static let shadowOffset = CGSize(width: 0, height: 2)
    
    // MARK: - Animations
    static let springAnimation = Animation.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
    static let easeOutAnimation = Animation.easeOut(duration: 0.3)
    static let easeInOutAnimation = Animation.easeInOut(duration: 0.4)
}

// MARK: - Custom View Modifiers
struct CardBackgroundModifier: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
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
            .foregroundColor(.white)
            .padding(.horizontal, AppTheme.largeSpacing)
            .padding(.vertical, AppTheme.spacing)
            .background(
                AppTheme.primaryGradient
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .cornerRadius(AppTheme.cornerRadius)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .shadow(
                color: AppTheme.primary.opacity(0.2),
                radius: configuration.isPressed ? 6 : 8,
                x: 0,
                y: configuration.isPressed ? 2 : 3
            )
            .animation(AppTheme.springAnimation, value: configuration.isPressed)
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
            .cornerRadius(AppTheme.cornerRadius)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(AppTheme.springAnimation, value: configuration.isPressed)
    }
}

struct FloatingActionButtonStyle: ButtonStyle {
    @State private var isPressed = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2.weight(.semibold))
            .foregroundColor(.white)
            .frame(width: 56, height: 56)
            .background(
                AppTheme.primary
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .clipShape(Circle())
            .shadow(
                color: AppTheme.primary.opacity(0.3),
                radius: configuration.isPressed ? 8 : 12,
                x: 0,
                y: configuration.isPressed ? 3 : 6
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(AppTheme.springAnimation, value: configuration.isPressed)
    }
}

// MARK: - View Extensions
extension View {
    func cardBackground() -> some View {
        modifier(CardBackgroundModifier())
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
                .font(.caption.weight(.medium))
                .foregroundColor(AppTheme.secondaryText)
        }
        .onAppear {
            withAnimation(AppTheme.springAnimation.delay(0.2)) {
                animatedValue = value
            }
        }
        .onChange(of: value) { newValue in
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
                .font(.system(size: 60, weight: .light))
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
            
            VStack(spacing: AppTheme.smallSpacing) {
                Text(title)
                    .font(.title2.weight(.semibold))
                    .foregroundColor(AppTheme.text)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.largeSpacing)
            }
            .slideInTransition()
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack(spacing: AppTheme.smallSpacing) {
                        Image(systemName: "plus.circle.fill")
                        Text(actionTitle)
                    }
                }
                .primaryButton()
                .padding(.top, AppTheme.spacing)
                .scaleTransition()
            }
            
            Spacer()
        }
        .padding(AppTheme.largeSpacing)
    }
}
