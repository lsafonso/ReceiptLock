//
//  TextFields.swift
//  ReceiptLock
//
//  Created by ReceiptLock AI Assistant.
//

import SwiftUI

struct ReceiptLockTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .sentences
    var autocorrectionDisabled: Bool = false
    var hasError: Bool = false
    var errorMessage: String? = nil
    
    // Focus handling
    var submitLabel: SubmitLabel = .return
    var onSubmit: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppTheme.text)
                
                if hasError {
                    Text("*")
                        .font(.headline)
                        .foregroundColor(AppTheme.error)
                }
                
                Spacer()
            }
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, AppTheme.spacing)
                .padding(.vertical, AppTheme.smallSpacing)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .fill(AppTheme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                .stroke(hasError ? AppTheme.error : AppTheme.separator, lineWidth: 1)
                        )
                )
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled(autocorrectionDisabled)
                .submitLabel(submitLabel)
                .onSubmit {
                    onSubmit?()
                }
            
            if let errorMessage = errorMessage, hasError {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(AppTheme.error)
                    .padding(.horizontal, AppTheme.spacing)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

