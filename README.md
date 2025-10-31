# ReceiptLock

> **📝 Documentation Updated**: This documentation has been updated as of January 2025 to reflect the current implementation with smart dashboard sorting functionality, appliance-based management, enhanced settings hierarchy, and complete security implementation.

A comprehensive iOS app for managing receipts and warranty information with OCR capabilities, local notifications, data export/import features, and enterprise-grade security.

## 📚 **Documentation**

- **README.md**: This file - comprehensive feature overview and user guide
- **PROJECT_REQUIREMENTS.md**: Detailed feature requirements and implementation status
- **PROJECT_IMPLEMENTATION_STATUS.md**: Current project completion status and roadmap
- **BUILD_INSTRUCTIONS.md**: Technical build and development instructions
- **SECURITY_IMPLEMENTATION.md**: Security features and implementation details
- **SECURITY_STATUS_SUMMARY.md**: Security assessment and compliance status
- **CURRENCY_IMPLEMENTATION_SUMMARY.md**: Multi-currency support details
- **USER_INTERACTION_IMPROVEMENTS.md**: Swipe action fixes and gesture enhancements

## Features

### 🔒 **Security & Privacy** ✅ **COMPLETE**
- **Data Encryption**: AES-256 encryption for all sensitive data using CryptoKit
- **Secure Storage**: Encrypted data storage with iOS Keychain integration
- **Privacy Controls**: GDPR-compliant consent management and data retention policies
- **Security Auditing**: Comprehensive security assessment and real-time monitoring
- **Data Export/Deletion**: Full GDPR compliance with data portability and right to be forgotten

### 💰 **Multi-Currency Support** ✅ **COMPLETE**
- **3 Supported Currencies**: USD (US Dollar), GBP (British Pound), EUR (Euro)
- **Dynamic Currency Switching**: Change currency preferences in settings
- **Global Updates**: All price displays update automatically
- **OCR Integration**: Receipt scanning adapts to selected currency
- **Persistent Storage**: Currency preferences saved automatically

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
- **Warranty Summary**: Overview of total devices, valid warranties, and expired warranties
- **Smart Appliance Sorting**: Sort appliances by Recently Added, Expiring Soon, Alphabetical, or Brand
- **Expandable Appliance Cards**: Interactive cards showing appliance details with expandable information
- **Store Badge System**: Dynamic retailer/store badges that display the purchase location with smart truncation
- **Floating Action Button**: Quick access to add new appliances
- **Enhanced User Interaction**: 
  - **Swipe Actions**: Left swipe to share, right swipe for edit/delete actions
  - **Long Press Alternative**: Long press (0.5s) to access action sheet with all options
  - **Visual Hints**: Clear indicators showing available swipe actions
  - **Gesture Separation**: Tap chevron to expand/collapse, swipe for actions - no conflicts

### Receipt List
- **Search & Filter**: Search by title/store and filter by status (All, Active, Expired, Expiring Soon)
- **Swipe to Delete**: Easy deletion with associated file cleanup
- **Navigation**: Tap to view detailed receipt information

### ⚙️ **Enhanced Settings Structure** ✅ **COMPLETE**
The app features a comprehensive, logically organized settings hierarchy:

#### **1. Profile & Personalization**
- **Profile Photo & Name**: Update avatar and display name with integrated profile management
- **Email Address**: Add and manage your email address
- **Currency Preferences**: Select from 3 supported currencies (USD, GBP, EUR)

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
- **Encryption Settings**: Data encryption levels and security configuration
- **Privacy Controls**: Data sharing consent and retention management

#### **5. Backup & Sync**
- **iCloud Sync**: Optional cross-device sync via CloudKit (toggle in Settings; restart required to apply)
- **Backup Settings**: Data backup and restore management
- **Import/Export (ZIP)**: Manual backup and restore using a ZIP that contains `backup.json` and embedded assets
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
- **CryptoKit**: AES-256 encryption and secure key management
- **Security Framework**: iOS Keychain integration for secure storage
- **Core Data Encryption**: Encrypted attributes and secure data persistence

### Architecture
- **MVVM Pattern**: Clean separation of concerns
- **Feature-based Organization**: Views organized by feature
- **Dependency Injection**: Core Data context injection
- **Error Handling**: Comprehensive error handling with user feedback
- **Persistence**: Core Data with optional NSPersistentCloudKitContainer for iCloud sync

### Data Model
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
│   │   ├── DashboardView.swift       # Dashboard with warranty overview and sorting
│   │   ├── ApplianceListView.swift   # Full appliance list with search/filter
│   │   ├── AddApplianceView.swift    # Add new appliance with comprehensive fields
│   │   ├── EditApplianceView.swift   # Edit existing appliance
│   │   ├── ApplianceDetailView.swift # Detailed appliance view
│   │   ├── ApplianceRowView.swift    # Appliance list item component
│   │   ├── ReceiptListView.swift     # Receipt list with search/filter
│   │   ├── ReceiptDetailView.swift   # Detailed receipt view
│   │   ├── AddReceiptView.swift      # Add new receipt
│   │   ├── EditReceiptView.swift     # Edit existing receipt
│   │   ├── CameraView.swift          # Camera interface for receipt scanning
│   │   ├── OnboardingView.swift      # Welcome tutorial for new users
│   │   ├── ProfileView.swift         # User profile management
│   │   └── SettingsView.swift        # Enhanced settings hierarchy
│   ├── 🔒 Security/                  # Security & Privacy
│   │   ├── DataEncryptionManager.swift
│   │   ├── SecureStorageManager.swift
│   │   ├── PrivacyManager.swift
│   │   ├── SecuritySettingsView.swift
│   │   └── KeychainWrapper.swift
│   ├── Managers/                     # Business logic
│   │   ├── NotificationManager.swift
│   │   ├── CurrencyManager.swift     # Multi-currency support
│   │   ├── UserProfile.swift         # Profile management
│   │   ├── ReminderSystem.swift      # Advanced reminder system
│   │   ├── DataBackupManager.swift   # Backup and sync
│   │   ├── ImageStorageManager.swift # Storage optimization
│   │   ├── OCRService.swift          # OCR text extraction
│   │   ├── CameraService.swift       # Camera integration
│   │   ├── PDFService.swift          # PDF generation and processing
│   │   ├── ValidationSystem.swift    # Input validation and error handling
│   │   └── AppTheme.swift            # Design system and theming
│   ├── ReceiptLock.xcdatamodeld/    # Core Data model
│   └── Assets.xcassets/             # App assets
├── ReceiptLockTests/                 # Unit tests
└── ReceiptLockUITests/              # UI tests
```

## Usage Guide

### Adding an Appliance
1. Tap the "+" floating action button on Dashboard or Appliances tab
2. **Camera Integration**: Take photos directly in the app or choose from photo library
3. **OCR Processing**: Automatically extract text and data from receipt images
4. **Smart Data Extraction**: Auto-fill appliance fields from scanned images
5. **Image Storage**: Store receipt images alongside data
6. **Comprehensive Information**: Fill in detailed appliance information:
   - **Basic Information**: Appliance name, store/brand, model, serial number
   - **Purchase Details**: Purchase date, price, warranty duration
   - **Warranty Information**: Warranty summary and additional notes
7. Save the appliance

### Managing Appliances
- **View**: Tap any appliance in the list to see details
- **Edit**: Use the menu in appliance details to edit
- **Delete**: Swipe left on list items or use menu in details
- **Search**: Use the search bar in the Appliances tab
- **Filter**: Use the segmented control to filter by status
- **Store Badges**: Each appliance displays a dynamic badge showing the retailer/store name with smart truncation for long names

### Dashboard Features
- **Warranty Summary**: Quick overview of warranty status across all devices
- **Smart Sorting**: Sort appliances by different criteria:
  - **Recently Added**: Shows newest appliances first
  - **Expiring Soon**: Shows warranties expiring soonest first
  - **Alphabetical**: Sorted by appliance name
  - **Brand**: Grouped by manufacturer
- **Expandable Cards**: Tap appliance cards to see more details
- **Store Badge System**: Dynamic retailer/store badges with smart truncation and accessibility features
- **Quick Actions**: Floating action button for adding new appliances

### ⚙️ **Settings Configuration**
The enhanced settings provide comprehensive control over your app experience:

#### **Profile & Personalization**
- Update your profile photo and display name
- Add and manage your email address
- Select your country/region with automatic currency detection
- Select your preferred currency from 20+ options (auto-set based on country)

#### **Receipt & Appliance Management**
- Organize appliances with custom categories
- Set default warranty reminder periods
- Configure storage preferences and optimization

#### **Notifications & Reminders**
- Set up multiple reminder notifications
- Customize notification sounds and styles
- Create personalized reminder messages

#### **Security & Privacy**
- Configure encryption settings
- Manage privacy controls and data consent

#### **Backup & Data Management**
- Enable iCloud sync for cross-device access (restart required after toggling)
- Export your data as ZIP (contains backup.json and assets)
- Import data from previous ZIP backups
- Monitor storage usage and cleanup options

### Notifications
- Configure default reminder days in Settings
- Notifications are automatically scheduled when appliances are saved
- Notifications appear before warranty expiry based on your settings

### Data Management
- **Export**: Creates a ZIP file with `backup.json` and embedded assets (images/PDFs)
- **Import**: Restore from a previously exported ZIP backup
- **Delete All**: Permanently removes all data (use with caution)

## Testing

### Unit Tests
Run unit tests with `Cmd+U` in Xcode. Tests cover:
- Date calculation logic
- Expiry status determination
- Price formatting
- Warranty validation
- Store badge truncation and fallback behavior
- Currency management
- Security features
- OCR processing

### UI Tests
Basic UI tests are included for core workflows:
- Add appliance flow
- OCR processing
- Save and reminder scheduling
- Settings navigation

## Permissions

The app requires the following permissions:
- **Notifications**: For warranty expiry reminders
- **Photo Library**: For selecting receipt images
- **File Access**: For importing/exporting data

### 🔒 **Security Permissions**
- **Keychain Access**: For secure storage of encryption keys and sensitive data
- **iCloud**: Enable the iCloud capability and container if using sync

## File Storage

Receipt files are stored in:
```
Documents/receipts/
├── appliance-uuid-1.jpg
├── appliance-uuid-2.pdf
└── ...
```

## Error Handling

The app includes comprehensive error handling for:
- Core Data operations
- File I/O operations
- OCR processing
- Notification scheduling
- User input validation
- Security operations
- Currency operations

## Accessibility

- VoiceOver labels on all interactive elements
- Dynamic Type support
- High contrast mode compatibility
- Focus states for navigation
- Store badge accessibility with full retailer names for screen readers

## Future Enhancements

### 🔒 **Security & Privacy** ✅ **COMPLETE**
- **All security features implemented and production-ready**

### ⚙️ **Settings & Configuration** ✅ **COMPLETE**
- **Enhanced settings hierarchy fully implemented and production-ready**

### 💰 **Multi-Currency Support** ✅ **COMPLETE**
- **3 currencies supported (USD, GBP, EUR) with dynamic switching**

### Core Features
- Cloud sync with iCloud ✅ **IMPLEMENTED**
- Multiple currency support ✅ **IMPLEMENTED**
- OCR text extraction ✅ **IMPLEMENTED**
- Appliance categorization ✅ **IMPLEMENTED**
- Receipt scanning and processing ✅ **IMPLEMENTED**
- Camera integration ✅ **IMPLEMENTED**
- PDF support ✅ **IMPLEMENTED**

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues or questions, please create an issue in the repository or contact the development team. 