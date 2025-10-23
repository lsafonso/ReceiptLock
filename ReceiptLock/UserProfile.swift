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
    var country: String
    var avatarData: Data?
    var preferences: UserPreferences
    
    init(name: String = "", email: String = "", country: String = "", avatarData: Data? = nil, preferences: UserPreferences = UserPreferences()) {
        self.name = name
        self.email = email
        self.country = country
        self.avatarData = avatarData
        self.preferences = preferences
    }
}

// MARK: - Countries
struct Country: Identifiable {
    let id: UUID
    let code: String
    let name: String
    
    init(code: String, name: String) {
        self.id = UUID()
        self.code = code
        self.name = name
    }
    
    static let allCountries = [
        Country(code: "US", name: "United States"),
        Country(code: "CA", name: "Canada"),
        Country(code: "GB", name: "United Kingdom"),
        Country(code: "AU", name: "Australia"),
        Country(code: "DE", name: "Germany"),
        Country(code: "FR", name: "France"),
        Country(code: "IT", name: "Italy"),
        Country(code: "ES", name: "Spain"),
        Country(code: "NL", name: "Netherlands"),
        Country(code: "BE", name: "Belgium"),
        Country(code: "CH", name: "Switzerland"),
        Country(code: "AT", name: "Austria"),
        Country(code: "SE", name: "Sweden"),
        Country(code: "NO", name: "Norway"),
        Country(code: "DK", name: "Denmark"),
        Country(code: "FI", name: "Finland"),
        Country(code: "IE", name: "Ireland"),
        Country(code: "PT", name: "Portugal"),
        Country(code: "GR", name: "Greece"),
        Country(code: "PL", name: "Poland"),
        Country(code: "CZ", name: "Czech Republic"),
        Country(code: "HU", name: "Hungary"),
        Country(code: "SK", name: "Slovakia"),
        Country(code: "SI", name: "Slovenia"),
        Country(code: "HR", name: "Croatia"),
        Country(code: "RO", name: "Romania"),
        Country(code: "BG", name: "Bulgaria"),
        Country(code: "LT", name: "Lithuania"),
        Country(code: "LV", name: "Latvia"),
        Country(code: "EE", name: "Estonia"),
        Country(code: "CY", name: "Cyprus"),
        Country(code: "MT", name: "Malta"),
        Country(code: "LU", name: "Luxembourg"),
        Country(code: "JP", name: "Japan"),
        Country(code: "KR", name: "South Korea"),
        Country(code: "CN", name: "China"),
        Country(code: "IN", name: "India"),
        Country(code: "BR", name: "Brazil"),
        Country(code: "MX", name: "Mexico"),
        Country(code: "AR", name: "Argentina"),
        Country(code: "CL", name: "Chile"),
        Country(code: "CO", name: "Colombia"),
        Country(code: "PE", name: "Peru"),
        Country(code: "VE", name: "Venezuela"),
        Country(code: "ZA", name: "South Africa"),
        Country(code: "EG", name: "Egypt"),
        Country(code: "NG", name: "Nigeria"),
        Country(code: "KE", name: "Kenya"),
        Country(code: "MA", name: "Morocco"),
        Country(code: "TN", name: "Tunisia"),
        Country(code: "DZ", name: "Algeria"),
        Country(code: "GH", name: "Ghana"),
        Country(code: "ET", name: "Ethiopia"),
        Country(code: "UG", name: "Uganda"),
        Country(code: "TZ", name: "Tanzania"),
        Country(code: "RW", name: "Rwanda"),
        Country(code: "SN", name: "Senegal"),
        Country(code: "CI", name: "Ivory Coast"),
        Country(code: "CM", name: "Cameroon"),
        Country(code: "MG", name: "Madagascar"),
        Country(code: "MZ", name: "Mozambique"),
        Country(code: "ZM", name: "Zambia"),
        Country(code: "ZW", name: "Zimbabwe"),
        Country(code: "BW", name: "Botswana"),
        Country(code: "NA", name: "Namibia"),
        Country(code: "SZ", name: "Eswatini"),
        Country(code: "LS", name: "Lesotho"),
        Country(code: "MW", name: "Malawi"),
        Country(code: "AO", name: "Angola"),
        Country(code: "CD", name: "Democratic Republic of the Congo"),
        Country(code: "CG", name: "Republic of the Congo"),
        Country(code: "CF", name: "Central African Republic"),
        Country(code: "TD", name: "Chad"),
        Country(code: "NE", name: "Niger"),
        Country(code: "ML", name: "Mali"),
        Country(code: "BF", name: "Burkina Faso"),
        Country(code: "GN", name: "Guinea"),
        Country(code: "SL", name: "Sierra Leone"),
        Country(code: "LR", name: "Liberia"),
        Country(code: "GM", name: "Gambia"),
        Country(code: "GW", name: "Guinea-Bissau"),
        Country(code: "CV", name: "Cape Verde"),
        Country(code: "ST", name: "São Tomé and Príncipe"),
        Country(code: "GQ", name: "Equatorial Guinea"),
        Country(code: "GA", name: "Gabon"),
        Country(code: "BI", name: "Burundi"),
        Country(code: "DJ", name: "Djibouti"),
        Country(code: "ER", name: "Eritrea"),
        Country(code: "SO", name: "Somalia"),
        Country(code: "SS", name: "South Sudan"),
        Country(code: "SD", name: "Sudan"),
        Country(code: "LY", name: "Libya")
    ]
    
    // Country to currency mapping (only supported currencies)
    static let countryToCurrency: [String: String] = [
        "US": "USD",
        "CA": "CAD", 
        "GB": "GBP",
        "AU": "AUD",
        "DE": "EUR",
        "FR": "EUR",
        "IT": "EUR",
        "ES": "EUR",
        "NL": "EUR",
        "BE": "EUR",
        "AT": "EUR",
        "FI": "EUR",
        "IE": "EUR",
        "PT": "EUR",
        "GR": "EUR",
        "LU": "EUR",
        "CY": "EUR",
        "MT": "EUR",
        "SI": "EUR",
        "SK": "EUR",
        "EE": "EUR",
        "LV": "EUR",
        "LT": "EUR",
        "CH": "CHF",
        "SE": "SEK",
        "NO": "NOK",
        "DK": "DKK",
        "PL": "PLN",
        "CZ": "CZK",
        "HU": "HUF",
        "RO": "RON",
        "BG": "BGN",
        "HR": "HRK",
        "JP": "JPY",
        "KR": "KRW",
        "CN": "CNY",
        "IN": "INR",
        "BR": "BRL",
        "MX": "MXN",
        "AR": "ARS",
        "CL": "CLP",
        "CO": "COP",
        "PE": "PEN",
        "VE": "VES",
        "ZA": "ZAR",
        "EG": "EGP",
        "NG": "NGN",
        "KE": "KES",
        "MA": "MAD",
        "TN": "TND",
        "DZ": "DZD",
        "GH": "GHS",
        "ET": "ETB",
        "UG": "UGX",
        "TZ": "TZS",
        "RW": "RWF",
        "SN": "XOF",
        "CI": "XOF",
        "CM": "XAF",
        "MG": "MGA",
        "MZ": "MZN",
        "ZM": "ZMW",
        "ZW": "ZWL",
        "BW": "BWP",
        "NA": "NAD",
        "SZ": "SZL",
        "LS": "LSL",
        "MW": "MWK",
        "AO": "AOA",
        "CD": "CDF",
        "CG": "XAF",
        "CF": "XAF",
        "TD": "XAF",
        "NE": "XOF",
        "ML": "XOF",
        "BF": "XOF",
        "GN": "GNF",
        "SL": "SLE",
        "LR": "LRD",
        "GM": "GMD",
        "GW": "XOF",
        "CV": "CVE",
        "ST": "STN",
        "GQ": "XAF",
        "GA": "XAF",
        "BI": "BIF",
        "DJ": "DJF",
        "ER": "ERN",
        "SO": "SOS",
        "SS": "SSP",
        "SD": "SDG",
        "LY": "LYD"
    ]
    
    // Get default currency for a country
    static func getDefaultCurrency(for countryName: String) -> String {
        // Find the country by name and return its currency
        if let country = allCountries.first(where: { $0.name == countryName }),
           let currency = countryToCurrency[country.code] {
            return currency
        }
        return "USD" // Default fallback
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
    @State private var email: String
    @State private var country: String
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingCountryPicker = false
    
    init() {
        self._name = State(initialValue: UserProfileManager.shared.currentProfile.name)
        self._email = State(initialValue: UserProfileManager.shared.currentProfile.email)
        self._country = State(initialValue: UserProfileManager.shared.currentProfile.country)
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
                    
                    // Country Section
                    countrySection
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
        .sheet(isPresented: $showingCountryPicker) {
            CountryPickerView(selectedCountry: $country)
        }
        .onChange(of: country) { _, newCountry in
            // Automatically update currency when country changes
            let newCurrency = Country.getDefaultCurrency(for: newCountry)
            
            // Only update if the currency is valid and different from current
            if CurrencyManager.shared.isValidCurrency(newCurrency) && 
               newCurrency != profileManager.currentProfile.preferences.preferredCurrency {
                var updatedPreferences = profileManager.currentProfile.preferences
                updatedPreferences.preferredCurrency = newCurrency
                profileManager.updatePreferences(updatedPreferences)
            }
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
    
    private var emailSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
            Text("Email")
                .font(.headline)
                .foregroundColor(AppTheme.text)
            
            TextField("Enter your email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding(.horizontal, AppTheme.spacing)
                .padding(.vertical, AppTheme.smallSpacing)
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.cornerRadius)
        }
    }
    
    private var countrySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
            Text("Country/Region")
                .font(.headline)
                .foregroundColor(AppTheme.text)
            
            Button(action: {
                showingCountryPicker = true
            }) {
                HStack {
                    Text(country.isEmpty ? "Select your country" : country)
                        .foregroundColor(country.isEmpty ? AppTheme.secondaryText : AppTheme.text)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppTheme.secondaryText)
                        .font(.caption)
                }
                .padding(.horizontal, AppTheme.spacing)
                .padding(.vertical, AppTheme.smallSpacing)
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
            }
        }
    }
    
    private func saveProfile() {
        var updatedProfile = profileManager.currentProfile
        updatedProfile.name = name
        updatedProfile.email = email
        updatedProfile.country = country
        
        // Update currency based on country
        let newCurrency = Country.getDefaultCurrency(for: country)
        if CurrencyManager.shared.isValidCurrency(newCurrency) {
            updatedProfile.preferences.preferredCurrency = newCurrency
        }
        
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

// MARK: - Country Picker View
struct CountryPickerView: View {
    @Binding var selectedCountry: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    private var filteredCountries: [Country] {
        if searchText.isEmpty {
            return Country.allCountries
        } else {
            return Country.allCountries.filter { country in
                country.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List(filteredCountries) { country in
                Button(action: {
                    selectedCountry = country.name
                    dismiss()
                }) {
                    HStack {
                        Text(country.name)
                            .foregroundColor(AppTheme.text)
                        
                        Spacer()
                        
                        if selectedCountry == country.name {
                            Image(systemName: "checkmark")
                                .foregroundColor(AppTheme.primary)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search countries")
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
