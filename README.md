# ReceiptLock

A comprehensive iOS app for managing receipts and warranty information with OCR capabilities, local notifications, and data export/import features.

## Features

### 🔒 **Security & Privacy** ✅ **COMPLETE**
- **Face ID/Touch ID Protection**: Biometric authentication with device passcode fallback
- **Data Encryption**: AES-256 encryption for all sensitive data using CryptoKit
- **Secure Storage**: Encrypted data storage with iOS Keychain integration
- **Privacy Controls**: GDPR-compliant consent management and data retention policies
- **Security Auditing**: Comprehensive security assessment and real-time monitoring
- **Auto-Lock System**: Configurable session timeout and biometric lock protection
- **Data Export/Deletion**: Full GDPR compliance with data portability and right to be forgotten

### Core Functionality
- **Receipt Management**: Create, edit, and delete receipts with detailed information
- **Warranty Tracking**: Automatic expiry date calculation based on purchase date and warranty months
- **Receipt Scanning & OCR**: Complete camera integration with intelligent text extraction
- **File Management**: Store receipt images and PDFs locally in Documents/receipts directory

### Receipt Scanning & OCR Features
- **Camera Integration**: Take photos of receipts directly in the app with optimized settings
- **OCR Processing**: Automatically extract text and data from receipt images using Vision framework
- **Smart Data Extraction**: Auto-fill receipt fields from scanned images with intelligent parsing
- **Image Storage**: Store receipt images alongside data with automatic optimization
- **Image Editing**: Built-in image editor with filters for better OCR results
- **PDF Support**: Import and process PDF documents with OCR text extraction
- **PDF Processing**: Convert PDF pages to images for enhanced OCR accuracy
- **Multi-format Support**: Handle both image-based and text-based PDFs
- **OCR Results Management**: Review and selectively apply extracted data

### Dashboard
- **Upcoming Expirations**: Shows warranties expiring within 30 days
- **Expired Warranties**: Displays expired warranties
- **Recent Receipts**: Shows the 5 most recently added receipts

### Receipt List
- **Search & Filter**: Search by title/store and filter by status (All, Active, Expired, Expiring Soon)
- **Swipe to Delete**: Easy deletion with associated file cleanup
- **Navigation**: Tap to view detailed receipt information

### ⚙️ **Enhanced Settings Structure** ✅ **COMPLETE**
The app features a comprehensive, logically organized settings hierarchy:

#### **1. Profile & Personalization**
- **Profile Photo & Name**: Update avatar and display name with integrated profile management
- **Currency Preferences**: Full currency selection with 20+ supported currencies
- **Language/Locale**: Comprehensive language selection (10+ languages)
- **Theme & Appearance**: System, Light, or Dark theme with dynamic switching

#### **2. Receipt & Appliance Settings**
- **Receipt Categories**: Manage receipt organization and categorization
- **Warranty Reminder Defaults**: Configure default reminder periods and behavior
- **Receipt Storage Preferences**: Manage storage compression and optimization

#### **3. Notifications & Reminders**
- **Reminder Settings**: Configure multiple reminders and custom messages
- **Active Reminders**: View and manage configured reminder counts
- **Notification Preferences**: Sound, badges, and alert style configuration
- **Custom Reminder Messages**: Personalize notification content

#### **4. Security & Privacy**
- **Biometric Authentication**: Face ID, Touch ID, and passcode configuration
- **Encryption Settings**: Data encryption levels and security configuration
- **Privacy Controls**: Data sharing consent and retention management

#### **5. Backup & Sync**
- **iCloud Sync**: Automatic cross-device synchronization
- **Backup Settings**: Data backup and restore management
- **Import/Export**: Manual backup and restore functionality
- **Last Backup Tracking**: Monitor backup status and timestamps

#### **6. Data Management**
- **Storage Usage**: View app storage and cleanup options
- **Data Export**: Export all receipts and files with compression
- **Data Deletion**: Permanently remove data with confirmation

#### **7. About & Support**
- **App Version**: Current version and build information
- **Terms & Privacy**: Legal documentation and privacy policy
- **Support & Feedback**: Help resources and feedback channels
- **Onboarding Reset**: Reset onboarding flow for new users

### Receipt Details
- **Full Information Display**: All receipt fields with expiry status
- **Image/PDF Preview**: View attached receipt files
- **Edit Capability**: Modify receipt information with OCR reprocessing
- **PDF Export**: Generate and share receipt summaries as PDF
- **Delete Function**: Remove receipts with confirmation

## Technical Stack

### Core Technologies
- **SwiftUI**: Modern declarative UI framework
- **Core Data**: Local data persistence with lightweight migrations
- **Vision Framework**: On-device OCR for text extraction
- **AVFoundation**: Camera integration for receipt scanning
- **PDFKit**: PDF generation and preview
- **UserNotifications**: Local notification scheduling
- **PhotosUI**: Image selection from photo library
- **FileManager**: Local file storage management

### 🔒 **Security Technologies**
- **LocalAuthentication**: Face ID and Touch ID biometric authentication
- **CryptoKit**: AES-256 encryption and secure key management
- **Security Framework**: iOS Keychain integration for secure storage
- **Core Data Encryption**: Encrypted attributes and secure data persistence

### Architecture
- **MVVM Pattern**: Clean separation of concerns
- **Feature-based Organization**: Views organized by feature
- **Dependency Injection**: Core Data context injection
- **Error Handling**: Comprehensive error handling with user feedback

### Data Model
```swift
Receipt Entity:
- id: UUID
- title: String
- store: String
- purchaseDate: Date
- price: Double
- warrantyMonths: Int16
- expiryDate: Date (calculated)
- fileName: String (optional)
- warrantySummary: String (optional)
- createdAt: Date
- updatedAt: Date
```

## Build Instructions

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0+ deployment target
- iPhone device or simulator

### Setup Steps

1. **Clone the Repository**
   ```bash
   git clone <repository-url>
   cd ReceiptLock
   ```

2. **Open in Xcode**
   ```bash
   open ReceiptLock.xcodeproj
   ```

3. **Build and Run**
   - Select your target device/simulator
   - Press `Cmd+R` to build and run
   - The app will request notification permissions on first launch

### Project Structure
```
ReceiptLock/
├── ReceiptLock/
│   ├── ReceiptLockApp.swift          # Main app entry point
│   ├── ContentView.swift             # Root tab view
│   ├── PersistenceController.swift   # Core Data stack
│   ├── Views/                        # Feature views
│   │   ├── DashboardView.swift
│   │   ├── ReceiptListView.swift
│   │   ├── AddReceiptView.swift
│   │   ├── EditReceiptView.swift
│   │   ├── ReceiptDetailView.swift
│   │   ├── ReceiptRowView.swift
│   │   └── SettingsView.swift        # Enhanced settings hierarchy
│   ├── 🔒 Security/                  # Security & Privacy
│   │   ├── AuthenticationWrapperView.swift
│   │   ├── BiometricAuthenticationManager.swift
│   │   ├── DataEncryptionManager.swift
│   │   ├── SecureStorageManager.swift
│   │   ├── PrivacyManager.swift
│   │   ├── SecuritySettingsView.swift
│   │   ├── AuthenticationService.swift
│   │   └── KeychainWrapper.swift
│   ├── Managers/                     # Business logic
│   │   ├── NotificationManager.swift
│   │   ├── CurrencyManager.swift     # Multi-currency support
│   │   ├── UserProfileManager.swift  # Profile management
│   │   ├── ReminderManager.swift     # Advanced reminder system
│   │   ├── DataBackupManager.swift   # Backup and sync
│   │   └── StorageManager.swift      # Storage optimization
│   ├── ReceiptLock.xcdatamodeld/    # Core Data model
│   └── Assets.xcassets/             # App assets
├── ReceiptLockTests/                 # Unit tests
└── ReceiptLockUITests/              # UI tests
```

## Usage Guide

### Adding a Receipt
1. Tap the "+" button on Dashboard or Receipts tab
2. **Camera Integration**: Take photos directly in the app or choose from photo library
3. **OCR Processing**: Automatically extract text and data from receipt images
4. **Smart Data Extraction**: Auto-fill receipt fields from scanned images
5. **Image Storage**: Store receipt images alongside data
6. Fill in any remaining receipt information (title, store, date, price, warranty)
7. Save the receipt

### Managing Receipts
- **View**: Tap any receipt in the list to see details
- **Edit**: Use the menu in receipt details to edit
- **Delete**: Swipe left on list items or use menu in details
- **Search**: Use the search bar in the Receipts tab
- **Filter**: Use the segmented control to filter by status

### ⚙️ **Settings Configuration**
The enhanced settings provide comprehensive control over your app experience:

#### **Profile & Personalization**
- Update your profile photo and display name
- Select your preferred currency from 20+ options
- Choose your language and locale
- Switch between system, light, or dark themes

#### **Receipt & Appliance Management**
- Organize receipts with custom categories
- Set default warranty reminder periods
- Configure storage preferences and optimization

#### **Notifications & Reminders**
- Set up multiple reminder notifications
- Customize notification sounds and styles
- Create personalized reminder messages

#### **Security & Privacy**
- Enable biometric authentication (Face ID/Touch ID)
- Configure encryption settings
- Manage privacy controls and data consent

#### **Backup & Data Management**
- Enable iCloud sync for cross-device access
- Export your data for backup
- Import data from previous backups
- Monitor storage usage and cleanup options

### Notifications
- Configure default reminder days in Settings
- Notifications are automatically scheduled when receipts are saved
- Notifications appear before warranty expiry based on your settings

### Data Management
- **Export**: Creates a ZIP file with JSON data and assets
- **Import**: Restore from a previously exported backup
- **Delete All**: Permanently removes all data (use with caution)

## Testing

### Unit Tests
Run unit tests with `Cmd+U` in Xcode. Tests cover:
- Date calculation logic
- Expiry status determination
- Price formatting
- Warranty validation

### UI Tests
Basic UI tests are included for core workflows:
- Add receipt flow
- OCR processing
- Save and reminder scheduling

## Permissions

The app requires the following permissions:
- **Notifications**: For warranty expiry reminders
- **Photo Library**: For selecting receipt images
- **File Access**: For importing/exporting data

### 🔒 **Security Permissions**
- **Face ID/Touch ID**: For biometric authentication (optional, with passcode fallback)
- **Keychain Access**: For secure storage of encryption keys and sensitive data

## File Storage

Receipt files are stored in:
```
Documents/receipts/
├── receipt-uuid-1.jpg
├── receipt-uuid-2.pdf
└── ...
```

## Error Handling

The app includes comprehensive error handling for:
- Core Data operations
- File I/O operations
- OCR processing
- Notification scheduling
- User input validation

## Accessibility

- VoiceOver labels on all interactive elements
- Dynamic Type support
- High contrast mode compatibility
- Focus states for navigation

## Future Enhancements

### 🔒 **Security & Privacy** ✅ **COMPLETE**
- **All security features implemented and production-ready**

### ⚙️ **Settings & Configuration** ✅ **COMPLETE**
- **Enhanced settings hierarchy fully implemented and production-ready**

### Core Features
- Cloud sync with iCloud ✅ **IMPLEMENTED**
- Multiple currency support ✅ **IMPLEMENTED**
- Enhanced OCR with machine learning
- Receipt categorization ✅ **IMPLEMENTED**
- Statistics and analytics
- Widget support
- Apple Watch companion app
- Batch OCR processing for multiple receipts
- Receipt template recognition for different store formats
- Advanced image preprocessing for better OCR accuracy

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues or questions, please create an issue in the repository or contact the development team. 