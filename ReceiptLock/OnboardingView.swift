//
//  OnboardingView.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject private var profileManager = UserProfileManager.shared
    @State private var currentPage = 0
    @State private var userName = ""
    @State private var showingImagePicker = false
    @State private var selectedAvatar: UIImage?
    
    private let onboardingPages = [
        OnboardingPage(
            title: "All your warranties, in one safe place.",
            subtitle: "Store receipts, cover, and purchase dates without the paperwork",
            imageName: "house.fill"
        ),
        OnboardingPage(
            title: "Add items in seconds.",
            subtitle: "Scan a receipt or barcode to fill in details automatically",
            imageName: "plus.circle.fill"
        ),
        OnboardingPage(
            title: "We'll remind you before the expiry date.",
            subtitle: "Choose 30, 14, or 7 day alerts so you never miss a claim",
            imageName: "bell.fill"
        )
    ]
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Page Content
                TabView(selection: $currentPage) {
                    ForEach(0..<onboardingPages.count, id: \.self) { index in
                        OnboardingPageView(page: onboardingPages[index])
                            .tag(index)
                    }
                    
                    // Profile Setup Page
                    profileSetupPage
                        .tag(onboardingPages.count)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                .accessibilityLabel("Onboarding slides")
                
                // Navigation Controls
                navigationControls
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedAvatar)
        }
    }
    
    private var profileSetupPage: some View {
        VStack(spacing: AppTheme.largeSpacing) {
            Spacer()
            
            // Avatar Section
            VStack(spacing: AppTheme.spacing) {
                AvatarView(
                    image: selectedAvatar,
                    size: 120,
                    showBorder: true
                )
                .onTapGesture {
                    showingImagePicker = true
                }
                
                Text("Tap to add photo")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            // Name Input
            VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
                Text("What's your name?")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(AppTheme.text)
                
                TextField("Enter your name", text: $userName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, AppTheme.spacing)
                    .padding(.vertical, AppTheme.smallSpacing)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(AppTheme.cornerRadius)
            }
            .padding(.horizontal, AppTheme.largeSpacing)
            
            Spacer()
        }
        .padding(AppTheme.largeSpacing)
    }
    
    private var navigationControls: some View {
        VStack(spacing: AppTheme.spacing) {
            // Page Indicators
            PaginationDots(
                currentPage: currentPage,
                totalPages: onboardingPages.count + 1
            )
            .padding(.bottom, AppTheme.spacing)
            
            // Navigation Buttons
            HStack {
                if currentPage == 0 {
                    Button("Skip") {
                        withAnimation {
                            currentPage = onboardingPages.count
                        }
                    }
                    .foregroundColor(AppTheme.secondaryText)
                    .accessibilityLabel("Skip onboarding")
                    .accessibilityHint("Skip to profile setup")
                } else if currentPage > 0 {
                    Button("Back") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                    .foregroundColor(AppTheme.secondaryText)
                }
                
                Spacer()
                
                if currentPage < onboardingPages.count {
                    Button("Next") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .primaryButton()
                    .accessibilityLabel("Next slide")
                    .accessibilityHint("Move to slide \(currentPage + 2) of \(onboardingPages.count + 1)")
                } else {
                    Button("Get started") {
                        completeOnboarding()
                    }
                    .primaryButton()
                    .accessibilityLabel("Get started")
                    .accessibilityHint("Complete onboarding and start using the app")
                }
            }
            .padding(.horizontal, AppTheme.largeSpacing)
            .padding(.bottom, AppTheme.largeSpacing)
        }
    }
    
    private func completeOnboarding() {
        // Save user profile
        var profile = profileManager.currentProfile
        profile.name = userName.isEmpty ? "User" : userName
        
        if let selectedAvatar = selectedAvatar {
            profileManager.setAvatarImage(selectedAvatar)
        }
        
        profileManager.updateProfile(profile)
        profileManager.completeOnboarding()
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let title: String
    let subtitle: String
    let imageName: String
    /// Optional semantic color override (e.g., warning, success)
    /// If nil, defaults to AppTheme.primary
    let semanticColor: Color? = nil
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: AppTheme.extraLargeSpacing) {
            Spacer()
            
            // Hero Icon
            HeroIcon(
                symbolName: page.imageName,
                semanticColor: page.semanticColor
            )
            
            // Text Content
            VStack(spacing: AppTheme.spacing) {
                Text(page.title)
                    .font(.title.weight(.bold))
                    .foregroundColor(AppTheme.text)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel(page.title)
                
                Text(page.subtitle)
                    .font(.body)
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.largeSpacing)
                    .accessibilityLabel(page.subtitle)
            }
            .slideInTransition()
            
            Spacer()
        }
        .padding(AppTheme.largeSpacing)
    }
}

// MARK: - Hero Icon Component
/// Reusable hero icon component for onboarding slides
/// Uses consistent sizing (96pt icon), brand green color, and animations
struct HeroIcon: View {
    let symbolName: String
    let semanticColor: Color?
    @State private var isAnimating = false
    
    /// Hero circle background color - defaults to brand green, allows semantic overrides
    private var heroColor: Color {
        semanticColor ?? AppTheme.primary
    }
    
    // Hero styling constants
    private let iconSize: CGFloat = 96
    private let circleFrame: CGFloat = 160
    private let shadowRadius: CGFloat = 20
    private let shadowOffset: CGFloat = 10
    private let shadowOpacity: Double = 0.3
    
    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: iconSize, weight: .light))
            .foregroundColor(heroColor.rlOn())
            .frame(width: circleFrame, height: circleFrame)
            .background(
                Circle()
                    .fill(heroColor)
                    .shadow(
                        color: heroColor.opacity(shadowOpacity),
                        radius: shadowRadius,
                        x: 0,
                        y: shadowOffset
                    )
            )
            .scaleEffect(isAnimating ? 1.1 : 1.0)
            .animation(
                Animation.easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Welcome Message View
struct WelcomeMessageView: View {
    @ObservedObject private var profileManager = UserProfileManager.shared
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: AppTheme.spacing) {
            HStack {
                AvatarView(
                    image: profileManager.getAvatarImage(),
                    size: 50,
                    showBorder: false
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Welcome back!")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                    
                    Text(profileManager.currentProfile.name.isEmpty ? "User" : profileManager.currentProfile.name)
                        .font(.title2.weight(.bold))
                        .foregroundColor(AppTheme.text)
                }
                
                Spacer()
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            .opacity(isVisible ? 1.0 : 0.0)
            .offset(y: isVisible ? 0 : 20)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    isVisible = true
                }
            }
        }
    }
}

// MARK: - Pagination Dots Component
struct PaginationDots: View {
    let currentPage: Int
    let totalPages: Int
    
    // Dot styling constants
    private let dotSize: CGFloat = 10
    private let dotSpacing: CGFloat = 9 // Total gap ≈ 8-10pt between dots
    private let activeScale: CGFloat = 1.0
    private let inactiveScale: CGFloat = 0.9
    
    var body: some View {
        HStack(spacing: 0) {
            Spacer()
            
            // Progress label
            Text("\(currentPage + 1) of \(totalPages)")
                .rlSubheadlineMuted()
                .padding(.trailing, 12)
            
            // Dots
            HStack(spacing: dotSpacing) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? AppTheme.primary : AppTheme.paginationInactive)
                        .frame(width: dotSize, height: dotSize)
                        .scaleEffect(index == currentPage ? activeScale : inactiveScale)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                        .accessibilityHidden(true)
                }
            }
            
            Spacer()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Slide \(currentPage + 1) of \(totalPages)")
        .accessibilityHint("Onboarding progress indicator")
    }
}
