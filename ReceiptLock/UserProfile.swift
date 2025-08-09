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
    var avatarData: Data?
    var preferences: UserPreferences
    
    init(name: String = "", avatarData: Data? = nil, preferences: UserPreferences = UserPreferences()) {
        self.name = name
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
        theme: ThemeMode = .system,
        notificationsEnabled: Bool = true,
        showWelcomeMessage: Bool = true,
        preferredCurrency: String = "USD"
    ) {
        self.theme = theme
        self.notificationsEnabled = notificationsEnabled
        self.showWelcomeMessage = showWelcomeMessage
        self.preferredCurrency = preferredCurrency
    }
}

// MARK: - App Theme Enum
enum ThemeMode: String, CaseIterable, Codable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
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
            self.currentProfile = profile
        } else {
            self.currentProfile = UserProfile()
        }
        
        self.hasCompletedOnboarding = userDefaults.bool(forKey: onboardingKey)
    }
    
    // MARK: - Profile Management
    func updateProfile(_ profile: UserProfile) {
        currentProfile = profile
        saveProfile()
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
        guard let avatarData = currentProfile.avatarData else { return nil }
        return UIImage(data: avatarData)
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
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    
    init() {
        self._name = State(initialValue: UserProfileManager.shared.currentProfile.name)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.largeSpacing) {
                    // Avatar Section
                    avatarSection
                    
                    // Name Section
                    nameSection
                    
                    // Preferences Section
                    preferencesSection
                }
                .padding(AppTheme.spacing)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
    }
    
    private var avatarSection: some View {
        VStack(spacing: AppTheme.spacing) {
            AvatarView(
                image: selectedImage ?? profileManager.getAvatarImage(),
                size: 100,
                showBorder: true
            )
            .onTapGesture {
                showingImagePicker = true
            }
            
            Text("Tap to change photo")
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
                .padding(.horizontal, AppTheme.spacing)
                .padding(.vertical, AppTheme.smallSpacing)
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.cornerRadius)
        }
    }
    
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            Text("Preferences")
                .font(.headline)
                .foregroundColor(AppTheme.text)
            
            VStack(spacing: AppTheme.smallSpacing) {
                HStack {
                    Text("Reminder Settings")
                    Spacer()
                    Text("Configure in Settings")
                        .foregroundColor(AppTheme.secondaryText)
                }
                
                Button("Open Settings") {
                    // This would typically navigate to settings
                    // For now, we'll just show a message
                }
                .foregroundColor(AppTheme.primary)
                .font(.caption)
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadius)
        }
    }
    
    private func saveProfile() {
        var updatedProfile = profileManager.currentProfile
        updatedProfile.name = name
        
        if let selectedImage = selectedImage {
            profileManager.setAvatarImage(selectedImage)
        }
        
        profileManager.updateProfile(updatedProfile)
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
