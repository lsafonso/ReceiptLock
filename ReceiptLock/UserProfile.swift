//
//  UserProfile.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI
import Foundation

// MARK: - User Profile Model
struct UserProfile: Codable {
    var name: String
    var email: String
    var avatarData: Data?
    var preferences: UserPreferences
    
    init(name: String = "", email: String = "", avatarData: Data? = nil, preferences: UserPreferences = UserPreferences()) {
        self.name = name
        self.email = email
        self.avatarData = avatarData
        self.preferences = preferences
    }
}


// MARK: - User Preferences
struct UserPreferences: Codable {
    var theme: ThemeMode
    var notificationsEnabled: Bool
    var showWelcomeMessage: Bool
    var preferredCurrency: String
    
    init(
        theme: ThemeMode = .light,
        notificationsEnabled: Bool = true,
        showWelcomeMessage: Bool = true,
        preferredCurrency: String = "GBP"
    ) {
        self.theme = theme
        self.notificationsEnabled = notificationsEnabled
        self.showWelcomeMessage = showWelcomeMessage
        self.preferredCurrency = preferredCurrency
    }
}

// MARK: - App Theme Enum
enum ThemeMode: String, CaseIterable, Codable {
    case light = "light"
    
    var displayName: String {
        return "Light"
    }
}

// MARK: - User Profile Manager
class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()
    
    @Published var currentProfile: UserProfile
    @Published var hasCompletedOnboarding: Bool
    
    private let userDefaults = UserDefaults.standard
    private let profileKey = "userProfile"
    private let onboardingKey = "hasCompletedOnboarding"
    
    private init() {
        // Load existing profile or create default
        if let data = userDefaults.data(forKey: profileKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            var updatedProfile = profile
            
            // Migration: Update existing USD users to GBP (new default)
            if updatedProfile.preferences.preferredCurrency == "USD" {
                updatedProfile.preferences.preferredCurrency = "GBP"
                // Save the updated profile
                if let updatedData = try? JSONEncoder().encode(updatedProfile) {
                    userDefaults.set(updatedData, forKey: profileKey)
                }
            }
            
            self.currentProfile = updatedProfile
        } else {
            self.currentProfile = UserProfile()
        }
        
        self.hasCompletedOnboarding = userDefaults.bool(forKey: onboardingKey)
        
        // Sync currency manager with user preferences
        CurrencyManager.shared.changeCurrency(to: currentProfile.preferences.preferredCurrency)
    }
    
    // MARK: - Profile Management
    func updateProfile(_ profile: UserProfile) {
        currentProfile = profile
        saveProfile()
        
        // Sync currency manager with updated preferences
        CurrencyManager.shared.changeCurrency(to: profile.preferences.preferredCurrency)
    }
    
    func updateName(_ name: String) {
        currentProfile.name = name
        saveProfile()
    }
    
    func updateAvatar(_ imageData: Data?) {
        currentProfile.avatarData = imageData
        saveProfile()
    }
    
    func updatePreferences(_ preferences: UserPreferences) {
        currentProfile.preferences = preferences
        saveProfile()
        
        // Update currency manager when preferences change
        CurrencyManager.shared.changeCurrency(to: preferences.preferredCurrency)
    }
    
    private func saveProfile() {
        if let data = try? JSONEncoder().encode(currentProfile) {
            userDefaults.set(data, forKey: profileKey)
        }
    }
    
    // MARK: - Onboarding Management
    func completeOnboarding() {
        hasCompletedOnboarding = true
        userDefaults.set(true, forKey: onboardingKey)
    }
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
        userDefaults.set(false, forKey: onboardingKey)
    }
    
    // MARK: - Profile Image Helpers
    func getAvatarImage() -> UIImage? {
        guard let avatarData = currentProfile.avatarData,
              !avatarData.isEmpty,
              let image = UIImage(data: avatarData) else {
            return nil
        }
        return image
    }
    
    func setAvatarImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        updateAvatar(imageData)
    }
}

// MARK: - Avatar View Component
struct AvatarView: View {
    let image: UIImage?
    let size: CGFloat
    let showBorder: Bool
    
    init(image: UIImage?, size: CGFloat = 60, showBorder: Bool = true) {
        self.image = image
        self.size = size
        self.showBorder = showBorder
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.4))
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(showBorder ? AppTheme.primary : Color.clear, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Profile Edit View
struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var profileManager = UserProfileManager.shared
    @State private var name: String
    @State private var email: String
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    
    init() {
        self._name = State(initialValue: UserProfileManager.shared.currentProfile.name)
        self._email = State(initialValue: UserProfileManager.shared.currentProfile.email)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.largeSpacing) {
                    // Avatar Section
                    avatarSection
                    
                    // Name Section
                    nameSection
                    
                    // Email Section
                    emailSection
                }
                .padding(AppTheme.spacing)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .lineLimit(1)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                        dismiss()
                    }
                    .lineLimit(1)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
    }
    
    private var avatarSection: some View {
        VStack(spacing: AppTheme.spacing) {
            Button(action: {
                showingImagePicker = true
            }) {
                ZStack {
                    AvatarView(
                        image: selectedImage ?? profileManager.getAvatarImage(),
                        size: 100,
                        showBorder: true
                    )
                    
                    // Plus icon overlay when no photo is selected
                    if selectedImage == nil && profileManager.getAvatarImage() == nil {
                        Circle()
                            .fill(AppTheme.primary.opacity(0.9))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "plus")
                                    .font(.title3.weight(.semibold))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 35, y: 35) // Bottom right corner
                            .shadow(color: AppTheme.primary.opacity(0.3), radius: 8, x: 0, y: 2)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(selectedImage == nil && profileManager.getAvatarImage() == nil ? "Tap to add photo" : "Tap to change photo")
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
        }
    }
    
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
            Text("Name")
                .font(.headline)
                .foregroundColor(AppTheme.text)
            
            TextField("Enter your name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.vertical, AppTheme.smallSpacing)
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.cornerRadius)
        }
    }
    
    private var emailSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
            Text("Email")
                .font(.headline)
                .foregroundColor(AppTheme.text)
            
            TextField("Enter your email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding(.vertical, AppTheme.smallSpacing)
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.cornerRadius)
        }
    }
    
    
    private func saveProfile() {
        var updatedProfile = profileManager.currentProfile
        updatedProfile.name = name
        updatedProfile.email = email
        
        // Update avatar data in the profile before saving
        if let selectedImage = selectedImage {
            if let imageData = selectedImage.jpegData(compressionQuality: 0.8) {
                updatedProfile.avatarData = imageData
            }
        }
        
        profileManager.updateProfile(updatedProfile)
        
        // Note: dismiss() is handled by the Save button action to avoid double dismissal
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

