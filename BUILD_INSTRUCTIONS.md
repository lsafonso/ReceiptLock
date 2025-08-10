# ReceiptLock - Build Instructions

## Quick Start

1. **Open the project in Xcode**
   ```bash
   open ReceiptLock.xcodeproj
   ```

2. **Select your target device**
   - Choose iPhone simulator or connected device
   - Ensure iOS 17.0+ is selected

3. **Build and Run**
   - Press `Cmd+R` to build and run
   - The app will request notification permissions on first launch

## Project Structure

The app is organized with a feature-based architecture:

```
ReceiptLock/
├── ReceiptLockApp.swift          # Main app entry point
├── ContentView.swift             # Root tab view
├── PersistenceController.swift   # Core Data stack
├── Views/                        # Feature views
│   ├── DashboardView.swift       # Dashboard with warranty overview and smart sorting
│   ├── ApplianceListView.swift   # Full appliance list with search/filter
│   ├── AddApplianceView.swift    # Add new appliance with OCR
│   ├── EditApplianceView.swift   # Edit existing appliance
│   ├── ApplianceDetailView.swift # Detailed appliance view
│   ├── ApplianceRowView.swift    # Appliance list item component
│   ├── ReceiptListView.swift     # Receipt list with search/filter
│   ├── ReceiptDetailView.swift   # Detailed receipt view
│   ├── AddReceiptView.swift      # Add new receipt
│   ├── EditReceiptView.swift     # Edit existing receipt
│   ├── CameraView.swift          # Camera interface for receipt scanning
│   ├── OnboardingView.swift      # Welcome tutorial for new users
│   ├── ProfileView.swift         # User profile management
│   └── SettingsView.swift        # Enhanced settings hierarchy
├── Managers/                     # Business logic
│   ├── NotificationManager.swift # Local notification handling
│   ├── CurrencyManager.swift     # Multi-currency support
│   ├── UserProfile.swift         # Profile management
│   ├── ReminderSystem.swift      # Advanced reminder system
│   ├── DataBackupManager.swift   # Backup and sync
│   ├── ImageStorageManager.swift # Storage optimization
│   ├── OCRService.swift          # OCR text extraction
│   ├── CameraService.swift       # Camera integration
│   ├── PDFService.swift          # PDF generation and processing
│   ├── ValidationSystem.swift    # Input validation and error handling
│   └── AppTheme.swift            # Design system and theming
└── ReceiptLock.xcdatamodeld/    # Core Data model
```

## Core Features Implemented

### ✅ Completed Features

1. **Core Data Integration**
   - Appliance entity with all required fields
   - Automatic expiry date calculation
   - Lightweight migrations support

2. **Smart Dashboard View**
   - **Warranty Summary Cards**: Overview of total devices, valid warranties, and expired warranties
   - **Smart Appliance Sorting**: Multiple sorting options:
     - Recently Added: Shows newest appliances first
     - Expiring Soon: Shows warranties expiring soonest first
     - Alphabetical: Sorted by appliance name
     - Brand: Grouped by manufacturer
   - **Expandable Appliance Cards**: Interactive cards with expandable information
   - **Store Badge System**: Dynamic retailer/store badges with smart truncation and accessibility features
   - **Floating Action Button**: Quick access to add new appliances

3. **Appliance Management**
   - Create, edit, delete appliances
   - Search and filter functionality
   - Swipe-to-delete with file cleanup

4. **Receipt Scanning & OCR**
   - Camera integration with AVFoundation
   - Vision framework for text extraction
   - Automatic field suggestion and auto-fill
   - Image processing, editing, and storage
   - PDF document support with OCR text extraction
   - PDF page conversion to images for enhanced OCR
   - OCR results management and selective application

5. **File Management**
   - Local storage in Documents/receipts/
   - Image and PDF support
   - Automatic file cleanup on deletion

6. **Notifications**
   - Local notification scheduling
   - Configurable reminder days
   - Automatic scheduling on appliance save

7. **⚙️ Enhanced Settings Structure** ✅ **COMPLETE**
   The app features a comprehensive, logically organized settings hierarchy:

   #### **Profile & Personalization**
   - Profile photo and name management
   - Currency preferences (20+ currencies)
   - Language and locale selection (10+ languages)
   - Theme and appearance settings

   #### **Receipt & Appliance Settings**
   - Receipt categories management
   - Warranty reminder defaults
   - Storage preferences and optimization

   #### **Notifications & Reminders**
   - Multiple reminder configuration
   - Notification preferences
   - Custom reminder messages

   #### **Security & Privacy**
   - Biometric authentication
   - Encryption settings
   - Privacy controls

   #### **Backup & Sync**
   - iCloud synchronization
   - Backup settings management
   - Import/export functionality

   #### **Data Management**
   - Storage usage monitoring
   - Data export and import
   - Data deletion with confirmation

   #### **About & Support**
   - App version information
   - Terms and privacy
   - Support and feedback
   - Onboarding reset

8. **💰 Multi-Currency Support** ✅ **COMPLETE**
   - **20+ Supported Currencies**: USD, EUR, GBP, CAD, AUD, JPY, CHF, CNY, INR, BRL, and more
   - **Dynamic Currency Switching**: Change currency preferences in settings
   - **Global Updates**: All price displays update automatically
   - **OCR Integration**: Receipt scanning adapts to selected currency
   - **Persistent Storage**: Currency preferences saved automatically

9. **🔒 Security & Privacy** ✅ **COMPLETE**
   - **Face ID/Touch ID Protection**: Biometric authentication with device passcode fallback
   - **Data Encryption**: AES-256 encryption for all sensitive data using CryptoKit
   - **Secure Storage**: Encrypted data storage with iOS Keychain integration
   - **Privacy Controls**: GDPR-compliant consent management and data retention policies
   - **Security Auditing**: Comprehensive security assessment and real-time monitoring
   - **Auto-Lock System**: Configurable session timeout and biometric lock protection

10. **🎨 User Experience & Onboarding** ✅ **COMPLETE**
    - **Onboarding Flow**: 4-step welcome tutorial with animated pages
    - **Profile Setup**: Name and avatar setup during onboarding
    - **Smooth Navigation**: Page indicators and animated transitions
    - **First-Time User Experience**: Automatic onboarding for new users
    - **Quick Actions**: Swipe gestures for quick edit/delete on appliance cards

11. **🔧 Data Validation & Error Handling** ✅ **COMPLETE**
    - **Input Validation**: Comprehensive validation for all forms with real-time feedback
    - **Error Handling**: User-friendly error messages and validation alerts
    - **Field Validation**: Price, warranty months, dates, and text field validation
    - **Required Field Indicators**: Visual indicators (*) for required fields
    - **Validation Rules**: Configurable validation rules with sensible defaults
    - **Form Validation**: Complete form validation before saving
    - **Error Banners**: Animated error banners showing all validation issues
    - **Haptic Feedback**: Tactile feedback for validation errors and success

12. **Accessibility**
    - VoiceOver labels
    - Dynamic Type support
    - Focus states

13. **Store Badge System**
    - Dynamic retailer/store badges replacing hardcoded "MOM" labels
    - Smart truncation for names longer than 8 characters
    - Fallback to "Unknown" for empty or invalid store names
    - Accessibility features with full store names for screen readers
    - Reactive updates when appliances are created or edited
    - Consistent badge styling across dashboard and appliance list views

### 🔧 Technical Implementation

**Core Data Model:**
```swift
Appliance Entity:
- id: UUID
- name: String
- brand: String
- model: String
- purchaseDate: Date
- warrantyMonths: Int16
- warrantyExpiryDate: Date (calculated)
- price: Double
- store: String
- receiptImage: Data? (optional)
- notes: String? (optional)
- createdAt: Date
- updatedAt: Date
```

**Dashboard Architecture:**
The smart dashboard uses a modular approach with:
- `SortOrder` enum for multiple sorting options
- `sortedAppliances` computed property for dynamic sorting
- `ExpandableApplianceCard` component for interactive appliance display
- State management for sort order selection
- Responsive layout with proper spacing and theming

**Store Badge Implementation:**
The store badge system provides dynamic retailer display:
- `storeBadgeText` computed property for smart truncation logic
- 8-character limit with ellipsis for long store names
- Fallback handling for empty or "Unknown" values
- Accessibility integration with full store names in tooltips
- Reactive updates through SwiftUI's data binding system

**Settings Architecture:**
The enhanced settings use a modular approach with:
- `SettingsSection` component for consistent section styling
- `SettingsRow` component for uniform row presentation
- State management through various managers
- Sheet presentations for detailed configuration views

**Multi-Currency Implementation:**
The currency system provides dynamic currency support:
- `CurrencyManager` singleton for centralized currency management
- 20+ supported currencies with proper formatting
- Dynamic currency symbol updates throughout the app
- OCR integration with currency-aware text extraction
- Persistent storage using UserDefaults

**Security Implementation:**
The security system provides enterprise-grade protection:
- `AuthenticationWrapperView` for protecting sensitive content
- `BiometricAuthenticationManager` for Face ID/Touch ID support
- `DataEncryptionManager` for AES-256 encryption
- `SecureStorageManager` for encrypted data storage
- `PrivacyManager` for GDPR compliance and consent management

## Build Configuration

### Requirements
- **Xcode**: 15.0 or later
- **iOS Deployment Target**: 17.0+
- **Swift Version**: 5.0
- **Device Support**: iPhone only
- **Architecture**: ARM64 (Apple Silicon + Intel)

### Dependencies
- **Core Data**: Built-in iOS framework
- **Vision**: Built-in iOS framework for OCR
- **PDFKit**: Built-in iOS framework for PDF handling
- **UserNotifications**: Built-in iOS framework
- **PhotosUI**: Built-in iOS framework for image picker
- **UIDocumentPicker**: Built-in iOS framework for file selection
- **LocalAuthentication**: Built-in iOS framework for biometrics
- **CryptoKit**: Built-in iOS framework for encryption
- **Security**: Built-in iOS framework for keychain

### Code Signing
- Development team signing required
- Provisioning profile for device testing
- App ID configuration in Apple Developer portal

## Testing

### Unit Tests
Run unit tests with `Cmd+U` in Xcode. Tests cover:
- Core Data operations
- Date calculation logic
- Expiry status determination
- Price formatting
- Warranty validation
- Currency management
- Security features
- Store badge truncation and fallback behavior
- OCR processing
- Validation system

### UI Tests
Basic UI tests are included for core workflows:
- App launch and navigation
- Tab switching
- Add appliance flow
- OCR processing
- Settings navigation
- Authentication flows
- Onboarding flow
- Profile management

### Security Tests
- Biometric authentication
- Encryption verification
- Privacy controls
- Data protection
- Security auditing
- Auto-lock functionality

## Troubleshooting

### Common Build Issues

1. **Swift Version Compatibility**
   - Ensure Xcode 15.0+ is used
   - Check Swift version in project settings

2. **iOS Deployment Target**
   - Set minimum iOS version to 17.0+
   - Check device compatibility

3. **Code Signing Issues**
   - Verify development team selection
   - Check provisioning profile configuration
   - Ensure App ID is properly configured

4. **Dependency Issues**
   - Clean build folder (Shift+Cmd+K)
   - Reset package caches
   - Check framework linking

### Runtime Issues

1. **Camera Permissions**
   - Ensure camera usage description is set
   - Check privacy settings on device

2. **Notification Permissions**
   - Request notification permissions on first launch
   - Check device notification settings

3. **Biometric Authentication**
   - Verify Face ID/Touch ID is set up on device
   - Check app permissions in device settings

## Performance Optimization

### Build Optimizations
- Enable optimization in release builds
- Use appropriate deployment target
- Minimize framework dependencies

### Runtime Optimizations
- Lazy loading for large lists
- Image caching and optimization
- Background processing for OCR
- Memory management for image handling

## Deployment

### App Store Preparation
1. **Version Management**: Update version and build numbers
2. **Code Signing**: Configure production certificates
3. **App Store Connect**: Prepare app metadata
4. **Testing**: Complete internal and external testing
5. **Submission**: Submit for App Store review

### Enterprise Distribution
1. **Provisioning**: Configure enterprise provisioning profiles
2. **Distribution**: Use enterprise distribution methods
3. **Updates**: Implement over-the-air update system

---

**Last Updated**: January 2025  
**Version**: 1.2.0  
**Status**: All core features implemented, ready for production deployment 