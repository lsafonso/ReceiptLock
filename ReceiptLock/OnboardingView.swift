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
            title: "Welcome to Appliance Warranty Tracker",
            subtitle: "Keep track of all your appliance warranties in one place",
            imageName: "house.fill",
            backgroundColor: AppTheme.primary
        ),
        OnboardingPage(
            title: "Smart Warranty Management",
            subtitle: "Never miss an expiry date with intelligent reminders and notifications",
            imageName: "bell.fill",
            backgroundColor: AppTheme.secondary
        ),
        OnboardingPage(
            title: "Quick & Easy Setup",
            subtitle: "Add appliances with photos, scan receipts, or manual entry",
            imageName: "plus.circle.fill",
            backgroundColor: AppTheme.accent
        ),
        OnboardingPage(
            title: "Stay Organized",
            subtitle: "Categorize appliances, track costs, and manage warranties efficiently",
            imageName: "list.bullet",
            backgroundColor: AppTheme.primary
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
            HStack(spacing: AppTheme.smallSpacing) {
                ForEach(0..<(onboardingPages.count + 1), id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? AppTheme.primary : AppTheme.secondaryText.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == currentPage ? 1.2 : 1.0)
                        .animation(.spring(), value: currentPage)
                }
            }
            .padding(.bottom, AppTheme.spacing)
            
            // Navigation Buttons
            HStack {
                if currentPage > 0 {
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
                } else {
                    Button("Get Started") {
                        completeOnboarding()
                    }
                    .primaryButton()
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
    let backgroundColor: Color
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: AppTheme.extraLargeSpacing) {
            Spacer()
            
            // Icon
            Image(systemName: page.imageName)
                .font(.system(size: 80, weight: .light))
                .foregroundColor(page.backgroundColor.rlOn())
                .frame(width: 160, height: 160)
                .background(
                    Circle()
                        .fill(page.backgroundColor)
                        .shadow(color: page.backgroundColor.opacity(0.3), radius: 20, x: 0, y: 10)
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
            
            // Text Content
            VStack(spacing: AppTheme.spacing) {
                Text(page.title)
                    .font(.title.weight(.bold))
                    .foregroundColor(AppTheme.text)
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.body)
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.largeSpacing)
            }
            .slideInTransition()
            
            Spacer()
        }
        .padding(AppTheme.largeSpacing)
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
