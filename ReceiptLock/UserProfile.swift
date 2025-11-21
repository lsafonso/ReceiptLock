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
    @State private var isSaving: Bool = false
    @State private var scrollOffset: CGFloat = 0
    
    // Tracking changes
    @State private var originalName: String
    @State private var originalEmail: String
    
    // Focus management
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name
        case email
    }
    
    init() {
        let currentProfile = UserProfileManager.shared.currentProfile
        self._name = State(initialValue: currentProfile.name)
        self._email = State(initialValue: currentProfile.email)
        self._originalName = State(initialValue: currentProfile.name)
        self._originalEmail = State(initialValue: currentProfile.email)
    }
    
    var hasChanges: Bool {
        let nameChanged = name.trimmingCharacters(in: .whitespacesAndNewlines) != originalName
        let emailChanged = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() != originalEmail.lowercased()
        let imageChanged = selectedImage != nil
        
        return nameChanged || emailChanged || imageChanged
    }
    
    var isEmailValid: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Page Header
                SheetHeaderView(
                    title: "Edit Profile",
                    isSaving: isSaving,
                    saveDisabled: !hasChanges,
                    onCancel: { dismiss() },
                    onSave: {
                        handleSave()
                    },
                    scrollOffset: scrollOffset
                )
                .padding(.top, 8) // Reduced from AppTheme.smallSpacing
                .background(AppTheme.background)
                .zIndex(1)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Track scroll offset
                        GeometryReader { geometry in
                            let offset = geometry.frame(in: .named("scroll")).minY
                            Color.clear
                                .preference(key: ScrollOffsetPreferenceKey.self, value: offset)
                        }
                        .frame(height: 0)
                        
                        VStack(spacing: AppTheme.largeSpacing) {
                            // Avatar Section
                            avatarSection
                            
                            VStack(alignment: .leading, spacing: AppTheme.spacing) {
                                Text("Profile Details")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(AppTheme.secondaryText)
                                    .accessibilityAddTraits(.isHeader)
                                
                                VStack(spacing: AppTheme.spacing) {
                                    // Name Section
                                    nameSection
                                    
                                    // Email Section
                                    emailSection
                                }
                            }
                        }
                        .padding(AppTheme.spacing)
                    }
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = max(0, -value)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
    }
    
    private var avatarSection: some View {
        Button(action: {
            showingImagePicker = true
        }) {
            VStack(spacing: AppTheme.spacing) {
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
                
                Text(selectedImage == nil && profileManager.getAvatarImage() == nil ? "Tap to add photo" : "Change")
                    .font(.caption)
                    .foregroundColor(AppTheme.primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Profile photo")
        .accessibilityHint("Double-tap to change profile photo")
    }
    
    private var nameSection: some View {
        ReceiptLockTextField(
            title: "Name",
            placeholder: "Enter your name",
            text: $name,
            textContentType: .name,
            autocapitalization: .words,
            submitLabel: .next,
            onSubmit: {
                focusedField = .email
            }
        )
        .focused($focusedField, equals: .name)
        .accessibilityLabel("Name, text field")
    }
    
    private var emailSection: some View {
        ReceiptLockTextField(
            title: "Email",
            placeholder: "Enter your email",
            text: $email,
            keyboardType: .emailAddress,
            textContentType: .emailAddress,
            autocapitalization: .never,
            autocorrectionDisabled: true,
            hasError: !email.isEmpty && !isEmailValid,
            errorMessage: "Enter a valid email address.",
            submitLabel: .done,
            onSubmit: {
                handleSave()
            }
        )
        .focused($focusedField, equals: .email)
        .accessibilityLabel("Email address, text field")
    }
    
    private func handleSave() {
        guard hasChanges else { return }
        
        // Trim inputs
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Validate
        guard !trimmedEmail.isEmpty else { return }
        
        // Simple email validation regex
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        guard emailPred.evaluate(with: trimmedEmail) else {
            // Trigger haptic for error?
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            return
        }
        
        isSaving = true
        
        // Update model
        var updatedProfile = profileManager.currentProfile
        updatedProfile.name = trimmedName
        updatedProfile.email = trimmedEmail
        
        // Update avatar data in the profile before saving
        if let selectedImage = selectedImage {
            if let imageData = selectedImage.jpegData(compressionQuality: 0.8) {
                updatedProfile.avatarData = imageData
            }
        }
        
        profileManager.updateProfile(updatedProfile)
        
        // Success feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        dismiss()
    }
    
    // Deprecated: Logic moved to handleSave
    private func saveProfile() {
        handleSave()
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

