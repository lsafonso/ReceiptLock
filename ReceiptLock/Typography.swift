//
//  Typography.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI

// MARK: - Typography System

/// Central typography system for consistent text styling across the app.
/// Maps to iOS Dynamic Type with proper weights and line heights.
struct Typography {
    /// Display style - Largest, boldest text
    static let display = Font.system(size: 34, weight: .bold, design: .default)
    
    /// Large Title - For main headings
    static let largeTitle = Font.largeTitle.weight(.bold)
    
    /// Title - For section headings
    static let title = Font.title.weight(.semibold)
    
    /// Title 2 - For secondary headings
    static let title2 = Font.title2.weight(.semibold)
    
    /// Title 3 - For tertiary headings
    static let title3 = Font.title3.weight(.semibold)
    
    /// Headline - For emphasized text
    static let headline = Font.headline.weight(.semibold)
    
    /// Subheadline - For secondary emphasized text
    static let subheadline = Font.subheadline
    
    /// Body - For regular body text
    static let body = Font.body
    
    /// Callout - For call-to-action text
    static let callout = Font.callout
    
    /// Caption - For small supporting text
    static let caption = Font.caption
    
    /// Caption 2 - For smallest supporting text
    static let caption2 = Font.caption2
    
    // MARK: - Line Heights
    
    static let displayLineHeight: CGFloat = 40
    static let largeTitleLineHeight: CGFloat = 42
    static let titleLineHeight: CGFloat = 28
    static let title2LineHeight: CGFloat = 22
    static let title3LineHeight: CGFloat = 20
    static let headlineLineHeight: CGFloat = 18
    static let subheadlineLineHeight: CGFloat = 20
    static let bodyLineHeight: CGFloat = 20
    static let calloutLineHeight: CGFloat = 18
    static let captionLineHeight: CGFloat = 16
    static let caption2LineHeight: CGFloat = 13
}

// MARK: - Typography View Extensions

extension View {
    // MARK: - Display & Titles
    
    /// Large display text with primary color
    func rlDisplay() -> some View {
        self.font(Typography.display)
            .foregroundColor(AppTheme.text)
            .lineSpacing(4)
    }
    
    /// Large title with primary color
    func rlLargeTitle() -> some View {
        self.font(Typography.largeTitle)
            .foregroundColor(AppTheme.text)
            .lineSpacing(4)
    }
    
    /// Title with primary color
    func rlTitle() -> some View {
        self.font(Typography.title)
            .foregroundColor(AppTheme.text)
            .lineSpacing(2)
    }
    
    /// Title 2 with primary color
    func rlTitle2() -> some View {
        self.font(Typography.title2)
            .foregroundColor(AppTheme.text)
            .lineSpacing(2)
    }
    
    /// Title 3 with primary color
    func rlTitle3() -> some View {
        self.font(Typography.title3)
            .foregroundColor(AppTheme.text)
            .lineSpacing(1)
    }
    
    /// Title with secondary color
    func rlTitleMuted() -> some View {
        self.font(Typography.title)
            .foregroundColor(AppTheme.secondaryText)
            .lineSpacing(2)
    }
    
    // MARK: - Headlines
    
    /// Headline with primary color
    func rlHeadline() -> some View {
        self.font(Typography.headline)
            .foregroundColor(AppTheme.text)
            .lineSpacing(1)
    }
    
    /// Headline with secondary color
    func rlHeadlineMuted() -> some View {
        self.font(Typography.headline)
            .foregroundColor(AppTheme.secondaryText)
            .lineSpacing(1)
    }
    
    /// Subheadline with primary color
    func rlSubheadline() -> some View {
        self.font(Typography.subheadline)
            .foregroundColor(AppTheme.text)
            .lineSpacing(1)
    }
    
    /// Subheadline with secondary color
    func rlSubheadlineMuted() -> some View {
        self.font(Typography.subheadline)
            .foregroundColor(AppTheme.secondaryText)
            .lineSpacing(1)
    }
    
    // MARK: - Body Text
    
    /// Body text with primary color
    func rlBody() -> some View {
        self.font(Typography.body)
            .foregroundColor(AppTheme.text)
            .lineSpacing(2)
    }
    
    /// Body text with secondary color
    func rlBodyMuted() -> some View {
        self.font(Typography.body)
            .foregroundColor(AppTheme.secondaryText)
            .lineSpacing(2)
    }
    
    // MARK: - Callouts
    
    /// Callout text with primary color
    func rlCallout() -> some View {
        self.font(Typography.callout)
            .foregroundColor(AppTheme.text)
            .lineSpacing(1)
    }
    
    /// Callout text with secondary color
    func rlCalloutMuted() -> some View {
        self.font(Typography.callout)
            .foregroundColor(AppTheme.secondaryText)
            .lineSpacing(1)
    }
    
    // MARK: - Captions
    
    /// Caption with primary color
    func rlCaption() -> some View {
        self.font(Typography.caption)
            .foregroundColor(AppTheme.text)
            .lineSpacing(1)
    }
    
    /// Caption with secondary color
    func rlCaptionMuted() -> some View {
        self.font(Typography.caption)
            .foregroundColor(AppTheme.secondaryText)
            .lineSpacing(1)
    }
    
    /// Caption 2 with primary color
    func rlCaption2() -> some View {
        self.font(Typography.caption2)
            .foregroundColor(AppTheme.text)
            .lineSpacing(0.5)
    }
    
    /// Caption 2 with secondary color
    func rlCaption2Muted() -> some View {
        self.font(Typography.caption2)
            .foregroundColor(AppTheme.secondaryText)
            .lineSpacing(0.5)
    }
    
    /// Caption with bold weight
    func rlCaptionStrong() -> some View {
        self.font(.caption.weight(.semibold))
            .foregroundColor(AppTheme.text)
            .lineSpacing(1)
    }
    
    /// Caption 2 with bold weight
    func rlCaption2Strong() -> some View {
        self.font(.caption2.weight(.semibold))
            .foregroundColor(AppTheme.text)
            .lineSpacing(0.5)
    }
}

