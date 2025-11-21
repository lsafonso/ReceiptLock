//
//  ButtonStyles.swift
//  ReceiptLock
//
//  Created for Save/Cancel button micro-interactions
//

import SwiftUI

// MARK: - Save Button State

enum SaveButtonState {
    case idle
    case loading
    case success
}

// MARK: - Primary Save Button Style (Text-only for toolbar)

struct PrimarySaveButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    var state: SaveButtonState = .idle
    @State private var underlineOpacity: Double = 0
    
    init(state: SaveButtonState = .idle) {
        self.state = state
    }
    
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 0) {
            Group {
                if state == .loading {
                    HStack(spacing: 6) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primary))
                            .scaleEffect(0.7)
                        Text("Saving…")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(AppTheme.primary)
                    }
                } else if state == .success {
                    HStack(spacing: 4) {
                        Text("Saved")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(AppTheme.primary)
                        Image(systemName: "checkmark")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(AppTheme.primary)
                    }
                } else {
                    configuration.label
                        .font(.headline.weight(.semibold))
                        .foregroundColor(AppTheme.primary)
                }
            }
            .frame(minHeight: 44) // Ensure ≥44pt touch target
            
            Rectangle()
                .fill(AppTheme.primary)
                .frame(height: 1)
                .opacity(underlineOpacity)
        }
        .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
        .opacity(isEnabled ? 1.0 : 0.4)
        .animation(AppTheme.snappyAnimation, value: configuration.isPressed)
        .animation(AppTheme.snappyAnimation, value: state)
        .animation(AppTheme.snappyAnimation, value: isEnabled)
        .onChange(of: configuration.isPressed) { oldValue, newValue in
            if newValue && !oldValue && isEnabled {
                // Light haptic on tap (skip when disabled)
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                
                // Animate underline in
                withAnimation(AppTheme.snappyAnimation) {
                    underlineOpacity = 1.0
                }
            } else if !newValue && oldValue {
                // Animate underline out
                withAnimation(AppTheme.snappyAnimation) {
                    underlineOpacity = 0.0
                }
            }
        }
    }
}

// MARK: - Secondary Cancel Button Style

struct SecondaryCancelButtonStyle: ButtonStyle {
    @State private var underlineOpacity: Double = 0
    
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 0) {
            configuration.label
                .font(.headline)
                .foregroundColor(AppTheme.primary)
                .frame(minHeight: 44) // Ensure touch target is ≥ 44pt
            
            Rectangle()
                .fill(AppTheme.primary)
                .frame(height: 1)
                .opacity(underlineOpacity)
        }
        .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
        .animation(AppTheme.snappyAnimation, value: configuration.isPressed)
        .onChange(of: configuration.isPressed) { oldValue, newValue in
            if newValue && !oldValue {
                // Light haptic on tap
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                
                // Animate underline in
                withAnimation(AppTheme.snappyAnimation) {
                    underlineOpacity = 1.0
                }
            } else if !newValue && oldValue {
                // Animate underline out
                withAnimation(AppTheme.snappyAnimation) {
                    underlineOpacity = 0.0
                }
            }
        }
    }
}

// MARK: - Cancel Button with Confirmation

struct CancelButton: View {
    let action: () -> Void
    var hasUnsavedChanges: Bool = false
    @State private var showingConfirmation = false
    
    var body: some View {
        Button {
            if hasUnsavedChanges {
                showingConfirmation = true
            } else {
                action()
            }
        } label: {
            Text("Cancel")
                .lineLimit(1)
        }
        .buttonStyle(SecondaryCancelButtonStyle())
        .confirmationDialog("Discard changes?", isPresented: $showingConfirmation, titleVisibility: .visible) {
            Button("Discard", role: .destructive) {
                action()
            }
            Button("Keep Editing", role: .cancel) { }
        }
    }
}

// MARK: - Save Button with State Management

struct SaveButton: View {
    let action: () -> Void
    @Binding var state: SaveButtonState
    var isDisabled: Bool = false
    let onSuccess: (() -> Void)?
    
    init(
        action: @escaping () -> Void,
        state: Binding<SaveButtonState>,
        isDisabled: Bool = false,
        onSuccess: (() -> Void)? = nil
    ) {
        self.action = action
        self._state = state
        self.isDisabled = isDisabled
        self.onSuccess = onSuccess
    }
    
    var body: some View {
        Button {
            guard !isDisabled && state != .loading else { return }
            
            state = .loading
            action()
        } label: {
            Text("Save")
        }
        .buttonStyle(PrimarySaveButtonStyle(state: state))
        .disabled(isDisabled || state == .loading)
        .opacity(isDisabled ? 0.4 : 1.0)
        .onChange(of: state) { _, newState in
            if newState == .success {
                // Auto-revert to idle after 0.8s
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation {
                        state = .idle
                    }
                    onSuccess?()
                }
            }
        }
    }
}

// MARK: - View Extension for Disabled State Opacity

extension View {
    func saveButtonDisabled(_ disabled: Bool) -> some View {
        self
            .opacity(disabled ? 0.4 : 1.0)
            .disabled(disabled)
    }
}

// MARK: - Scroll Offset Preference Key

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Shared Sheet Header

struct SheetHeaderView: View {
    let title: String
    let isSaving: Bool
    var saveDisabled: Bool = false
    let onCancel: () -> Void
    let onSave: () -> Void
    var scrollOffset: CGFloat = 0 // Track scroll offset for divider visibility
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Centered Title
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(AppTheme.text)
                    .multilineTextAlignment(.center)
                
                // Left and Right Buttons
                HStack {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(AppTheme.primary)
                            .padding(.vertical, 12)
                            .padding(.trailing, 12) // Hit area expansion
                            .contentShape(Rectangle())
                    }
                    
                    Spacer()
                    
                    Button(action: onSave) {
                        Text(isSaving ? "Saving..." : "Save")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(isSaving || saveDisabled ? AppTheme.secondaryText.opacity(0.6) : AppTheme.primary)
                            .padding(.vertical, 12)
                            .padding(.leading, 12) // Hit area expansion
                            .contentShape(Rectangle())
                    }
                    .disabled(isSaving || saveDisabled)
                }
            }
            .frame(minHeight: 44)
            .padding(.horizontal, 24)
            .padding(.top, 12)
            
            // Subtle divider that appears when scrolled
            if scrollOffset > 0 {
                Divider()
                    .background(AppTheme.separator.opacity(0.5))
                    .padding(.horizontal, 24)
            }
        }
    }
}
