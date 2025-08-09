# Appliance Warranty Tracker iOS App - Project Requirements

## Overview
Appliance Warranty Tracker is a comprehensive iOS app for managing appliance warranties and tracking expiry dates. The app operates locally without a backend, storing all data using Core Data and managing attachments through the device's file system. The app features a modern, clean design with muted green color scheme and intuitive user interface.

## Technical Stack
- **Language**: Swift 5.0
- **UI Framework**: SwiftUI with NavigationStack and TabView
- **Architecture**: MVVM with feature-based organization
- **Persistence**: Core Data with lightweight migrations
- **Platform**: iPhone-only (iOS 18.5+)
- **Deployment**: Local app (no backend required)
- **Design System**: Custom AppTheme with muted green color palette

## Core Features

### 1. Authentication
- **Type**: None (local app)
- **Access**: Direct app access without login

### 2. Appliance Management
- **CRUD Operations**: Create, Read, Update, Delete appliances
- **Required Fields**:
  - Title (String) - Appliance name
  - Store (String) - Brand or store name
  - Purchase Date (Date)
  - Price (Double)
  - Warranty Months (Int16)
  - Expiry Date (Date) - Auto-calculated
  - Warranty Summary (String) - Generated from OCR
  - File Name (String) - For attachment reference

### 3. Appliance Categories
- **25+ Device Types**: Air Conditioner, Laptop, Mobile, Refrigerator, etc.
- **Smart Selection**: Grid-based category selection with icons
- **Auto-fill**: Category selection automatically fills appliance name
- **Color Coding**: Each category has distinct color and icon

### 4. Attachments
- **Supported Formats**: JPEG images and PDFs
- **Storage**: Local file system under `Documents/receipts/`
- **OCR Processing**: On-device text extraction using Vision framework
- **Auto-fill**: Suggest field values from OCR results
- **Summary Generation**: Create warranty summary from extracted text

### 5. Receipt Scanning & OCR
- **Camera Integration**: Take photos of receipts directly in the app with optimized settings
- **OCR Processing**: Automatically extract text and data from receipt images using Vision framework
- **Smart Data Extraction**: Auto-fill receipt fields from scanned images with intelligent parsing
- **Image Storage**: Store receipt images alongside data with automatic optimization
- **Image Editing**: Built-in image editor with filters for better OCR results
- **PDF Support**: Import and process PDF documents with OCR text extraction
- **PDF Processing**: Convert PDF pages to images for enhanced OCR accuracy
- **Multi-format Support**: Handle both image-based and text-based PDFs
- **OCR Results Management**: Review and selectively apply extracted data

### 6. Dashboard (Home)
- **Warranty Summary Card**: Three-column display showing:
  - All devices (total count)
  - Valid warranties (active count)
  - Expired warranties (expired count)
- **Recent Appliances**: Latest 3 added appliances
- **Quick Actions**: Add new appliance button
- **Clean Design**: No navigation title, minimal interface

### 7. Appliance List
- **Search**: Text-based search across all fields
- **Filters**: All, Valid, Expired, Expiring Soon
- **Interactive Chips**: Animated filter selection with counts
- **Actions**: Edit, delete, share
- **Progress Indicators**: Visual warranty progress bars

### 8. Navigation Structure
- **Tab Bar**: 4 main sections
  - Home: Dashboard with warranty overview
  - Appliances: Complete appliance list
  - Add: Central floating action button
  - Profile: User settings and preferences

### 9. Notifications
- **Local Reminders**: Before warranty expiry
- **Configurable**: Default reminder days (7, 14, 30)
- **Smart Scheduling**: Only for future expiry dates
- **Permission Handling**: Request notification access

### 10. Settings (Profile)
- **Default Reminder Days**: Configurable (7, 14, 30 days)
- **Theme**: System, Light, Dark modes
- **Data Export**: ZIP with JSON + assets
- **Data Import**: Restore from exported data
- **Data Management**: Delete all data option

### 11. Share Functionality
- **PDF Export**: Single appliance as PDF summary
- **Content**: Appliance details + attached image
- **Share Sheet**: Native iOS sharing

## Design System

### Color Palette
- **Primary**: Muted Green (`#336666`) - Main actions and branding
- **Secondary**: Light Green (`#66CC99`) - Secondary actions
- **Background**: Soft Beige (`#FAF5F0`) - Warm, inviting background
- **Card Background**: White (`#FFFFFF`) - Clean card surfaces
- **Text**: Dark (`#1A1A1A`) - Primary text
- **Secondary Text**: Light Gray (`#666666`) - Secondary information
- **Success**: Green (`#34C759`) - Valid warranties
- **Warning**: Orange (`#FF9500`) - Expiring warranties
- **Error**: Red (`#DC3545`) - Expired warranties

### Interactive Elements
- **Floating Action Button**: Muted green with shadow and animations
- **Filter Chips**: Animated selection with haptic feedback
- **Progress Bars**: Visual warranty progress indicators
- **Empty States**: Animated placeholders with helpful messages
- **Card Shadows**: Subtle depth with consistent styling

### Animations
- **Spring Animations**: Smooth, natural transitions
- **Haptic Feedback**: Tactile response for interactions
- **Staggered Animations**: Sequential element appearances
- **Pulse Effects**: Visual urgency for expiring warranties

## Security & Privacy Implementation ✅ **COMPLETED**

### Security Architecture
ReceiptLock implements a comprehensive multi-layered security system that protects user data at every level:

#### **Authentication System**
- **Biometric Authentication**: Face ID and Touch ID support with device passcode fallback
- **Authentication Wrapper**: All sensitive content protected by AuthenticationWrapperView
- **Feature-Based Security**: Different security levels for different app features
- **Session Management**: Automatic session expiration and security monitoring

#### **Data Protection**
- **Encryption**: AES-256 encryption for all sensitive data using CryptoKit
- **Key Management**: Secure key generation, storage, and rotation using iOS Keychain
- **Secure Storage**: Encrypted Core Data attributes and secure file storage
- **Data Backup**: Encrypted backup and restore functionality

#### **Privacy & Compliance**
- **GDPR Compliance**: Full user rights implementation (export, deletion, consent)
- **Consent Management**: Granular consent for different data processing activities
- **Data Retention**: Configurable retention policies with automatic cleanup
- **Privacy Controls**: User-configurable privacy settings and data sharing preferences

#### **Security Monitoring**
- **Security Auditing**: Comprehensive security assessment and scoring
- **Real-time Monitoring**: Security status tracking and alerting
- **Compliance Checking**: Automated privacy and security compliance validation

### Security Integration
- **AuthenticationWrapperView**: Protects all sensitive app content
- **SecuritySettingsView**: Comprehensive security and privacy configuration
- **PrivacyManager**: Centralized privacy controls and consent management
- **SecureStorageManager**: Encrypted data storage and management
- **DataEncryptionManager**: Cryptographic operations and key management

## Technical Requirements
- **Model**: Receipt entity (repurposed for appliances)
- **Migrations**: Lightweight migrations for schema changes
- **Relationships**: None (simple entity structure)
- **Indexing**: Optimized for search and filtering

### File Management
- **Directory**: `Documents/receipts/`
- **Naming**: UUID-based file names
- **Cleanup**: Automatic file deletion with appliance deletion
- **Backup**: Included in app backup/restore

### Vision Framework Integration
- **OCR Processing**: Asynchronous text extraction
- **Error Handling**: Graceful fallback for failed OCR
- **Performance**: Background processing to avoid UI blocking
- **Language Support**: English text recognition

### PDF Generation
- **Content**: Appliance details + embedded image
- **Format**: Professional layout with branding
- **Sharing**: Native iOS share sheet integration

### User Notifications
- **Permission**: Request on first app launch
- **Scheduling**: Based on expiry date - reminder days
- **Content**: Appliance title and expiry date
- **Management**: Cancel notifications when appliances deleted

## UI/UX Requirements

### Accessibility
- **VoiceOver**: Complete label support
- **Dynamic Type**: Scalable text sizes
- **Focus States**: Clear navigation indicators
- **Color Contrast**: WCAG compliant

### Error Handling
- **Empty States**: Helpful messages for no data
- **Loading States**: Progress indicators
- **Error Messages**: User-friendly error descriptions
- **Recovery**: Clear actions for error resolution

### Performance
- **Lazy Loading**: Images and large content
- **Background Processing**: OCR and file operations
- **Memory Management**: Efficient image handling
- **Smooth Animations**: 60fps transitions

## Testing Requirements

### Unit Tests
- **Date Calculations**: Expiry date computation
- **Price Formatting**: Currency display
- **Warranty Validation**: Month calculations
- **OCR Processing**: Text extraction accuracy

### UI Tests
- **Add Flow**: Complete appliance creation
- **OCR Integration**: Image selection to text extraction
- **Save Process**: Core Data persistence
- **Notification Setup**: Reminder scheduling

## Non-Functional Requirements

### Code Quality
- **SwiftLint**: Code formatting compliance
- **Comments**: Comprehensive documentation
- **Error Handling**: Robust error management
- **Memory Management**: No memory leaks

### Security
- **Local Storage**: All data stays on device
- **File Access**: Sandboxed file operations
- **No Network**: Completely offline operation

### Performance
- **Launch Time**: < 2 seconds
- **OCR Processing**: < 5 seconds per image
- **Search**: Instant results
- **Memory Usage**: < 100MB typical

## File Structure
```
ReceiptLock/
├── ReceiptLock/
│   ├── ReceiptLockApp.swift
│   ├── ContentView.swift
│   ├── DashboardView.swift
│   ├── ApplianceListView.swift
│   ├── AddApplianceView.swift
│   ├── ApplianceDetailView.swift
│   ├── ApplianceRowView.swift
│   ├── CommunityView.swift
│   ├── ProfileView.swift
│   ├── SettingsView.swift
│   ├── NotificationManager.swift
│   ├── PersistenceController.swift
│   ├── AppTheme.swift
│   ├── ReceiptLock.xcdatamodeld/
│   └── Assets.xcassets/
├── ReceiptLockTests/
├── ReceiptLockUITests/
└── README.md
```

## Dependencies
- **Core Data**: Built-in iOS framework
- **Vision**: Built-in iOS framework for OCR
- **PDFKit**: Built-in iOS framework for PDF handling
- **UserNotifications**: Built-in iOS framework
- **PhotosUI**: Built-in iOS framework for image picker
- **UIDocumentPicker**: Built-in iOS framework for file selection

## Build Configuration
- **Swift Version**: 5.0
- **iOS Deployment Target**: 18.5+
- **Device Support**: iPhone only
- **Architecture**: ARM64
- **Code Signing**: Development team

## Success Criteria
- [x] App builds and runs without errors
- [x] All CRUD operations work correctly
- [x] OCR successfully extracts text from images
- [x] Notifications are scheduled and delivered
- [x] PDF export generates readable documents
- [x] Data export/import functions properly
- [x] Modern UI/UX with muted green design
- [x] Interactive elements with animations
- [x] Appliance categories with smart selection
- [x] Clean dashboard without navigation title
- [x] Consistent color scheme throughout app
- [x] **Face ID/Touch ID authentication working correctly**
- [x] **Data encryption properly implemented and tested**
- [x] **Privacy settings configurable and functional**
- [x] **Consent management working correctly**
- [x] **Auto-lock functionality working as expected**
- [x] **Security auditing comprehensive and accurate**
- [x] **Data retention policies enforced**
- [x] **GDPR compliance features complete**
- [x] **Error handling graceful and user-friendly**
- [x] **Security monitoring active and functional**
- [ ] All UI tests pass
- [ ] All unit tests pass
- [ ] Accessibility features work correctly
- [ ] Performance meets requirements

## Planned Improvements

### 🚀 **High Priority Features** (Selected for Implementation)

#### **User Experience & Personalization** ✅ **COMPLETED**
- [x] **Personalization**: Add user profile with name, avatar, and preferences
- [x] **Onboarding Flow**: Create a welcome tutorial for first-time users
- [x] **Quick Actions**: Add swipe gestures for quick edit/delete on appliance cards

#### **Data Management & Sync**
- [ ] **Cloud Sync**: Add iCloud sync for data backup and cross-device access
- [ ] **Data Export Formats**: Support CSV, PDF reports, and calendar integration
- [ ] **Bulk Operations**: Allow selecting multiple appliances for batch actions
- [ ] **Data Validation**: Add input validation and error handling for all forms

#### **Notifications & Integration**
- [ ] **Multiple Reminders**: Allow setting multiple reminder dates (7, 14, 30 days)
- [ ] **Calendar Integration**: Add warranty dates to device calendar

#### **Smart Features & OCR**
- [ ] **OCR Enhancement**: Improve text recognition accuracy and field mapping
- [ ] **Barcode Scanning**: Add barcode/QR code scanning for quick appliance lookup
- [ ] **Smart Suggestions**: Suggest warranty periods based on appliance type

#### **Performance & Optimization**
- [ ] **Lazy Loading**: Implement proper lazy loading for large lists
- [ ] **Caching**: Add image and data caching for better performance
- [ ] **Memory Management**: Optimize image handling and storage

#### **Security & Privacy** ✅ **COMPLETED**
- [x] **Face ID/Touch ID Protection**: Complete biometric authentication system with fallback to device passcode
- [x] **Data Encryption**: AES-256 encryption for all sensitive data with secure key management
- [x] **Privacy Controls**: GDPR-compliant consent management and data retention policies
- [x] **Secure Storage**: Encrypted data storage with keychain integration and secure backup
- [x] **Security Auditing**: Comprehensive security assessment and monitoring tools
- [x] **Auto-Lock**: Configurable session timeout and biometric lock protection
- [x] **Privacy Settings**: Complete privacy configuration and consent management

#### **UI/UX Enhancements**
- [ ] **Progress Indicators**: Add visual progress bars for warranty periods
- [ ] **Empty States**: Enhance empty state designs with helpful illustrations

### 📋 **Updated Implementation Priority Order**
1. ✅ **Personalization (User Profile)** - COMPLETED
2. ✅ **Onboarding Flow** - COMPLETED
3. ✅ **Quick Actions (Swipe Gestures)** - COMPLETED
4. ✅ **Data Validation** - COMPLETED
5. **Multiple Reminders**
6. **Progress Indicators**
7. **Empty States Enhancement**
8. **Lazy Loading**
9. **Caching**
10. **Memory Management**
11. **OCR Enhancement**
12. **Smart Suggestions**
13. **Barcode Scanning**
14. **Calendar Integration**
15. **Cloud Sync**
16. **Data Export Formats**
17. **Bulk Operations**
18. ✅ **Data Encryption** - COMPLETED
19. ✅ **Privacy Controls** - COMPLETED
20. ✅ **Secure Storage** - COMPLETED

### 🎉 **Recently Completed Features**

#### **Personalization System**
- ✅ **User Profile Management**: Complete user profile with name, avatar, and preferences
- ✅ **Profile Editor**: Full-featured profile editing with image picker
- ✅ **User Preferences**: Theme settings, reminder preferences, and app settings
- ✅ **Avatar System**: Custom avatar with image picker and fallback icons

#### **Onboarding Flow**
- ✅ **Welcome Tutorial**: 4-step onboarding with animated pages
- ✅ **Profile Setup**: Name and avatar setup during onboarding
- ✅ **Smooth Navigation**: Page indicators and animated transitions
- ✅ **First-Time User Experience**: Automatic onboarding for new users

#### **Quick Actions**
- ✅ **Swipe Gestures**: Left swipe for share, right swipe for edit/delete
- ✅ **Edit Actions**: Quick edit with sheet presentation
- ✅ **Delete Actions**: Confirmation dialog with haptic feedback
- ✅ **Share Actions**: Native share sheet with appliance details
- ✅ **Haptic Feedback**: Tactile response for all interactions

#### **Data Validation System**
- ✅ **Comprehensive Validation**: Input validation for all forms with real-time feedback
- ✅ **Error Handling**: User-friendly error messages and validation alerts
- ✅ **Field Validation**: Price, warranty months, dates, and text field validation
- ✅ **Required Field Indicators**: Visual indicators (*) for required fields
- ✅ **Validation Rules**: Configurable validation rules with sensible defaults
- ✅ **Form Validation**: Complete form validation before saving
- ✅ **Error Banners**: Animated error banners showing all validation issues
- ✅ **Haptic Feedback**: Tactile feedback for validation errors and success
- ✅ **Data Sanitization**: Automatic trimming of whitespace and data cleaning
- ✅ **Notification Integration**: Automatic notification scheduling after successful save

#### **Security & Privacy System** ✅ **COMPLETED**
- ✅ **Biometric Authentication**: Face ID and Touch ID support with device passcode fallback
- ✅ **Data Encryption**: AES-256 encryption for all sensitive data using CryptoKit
- ✅ **Secure Storage**: Encrypted data storage with iOS Keychain integration
- ✅ **Privacy Management**: GDPR-compliant consent management and data retention policies
- ✅ **Security Auditing**: Comprehensive security assessment and real-time monitoring
- ✅ **Auto-Lock System**: Configurable session timeout and biometric lock protection
- ✅ **Privacy Controls**: User-configurable privacy settings and data sharing preferences
- ✅ **Data Export/Deletion**: Full GDPR compliance with data portability and right to be forgotten
- ✅ **Security Settings**: Complete security configuration and monitoring interface

### 🚀 **Next Priority Features to Implement**

#### **5. Multiple Reminders** (High Impact)
- Allow setting 7, 14, and 30-day reminders
- Multiple notification scheduling
- Custom reminder messages
- Reminder management interface

#### **6. Progress Indicators** (UI Enhancement)
- Visual progress bars for warranty periods
- Animated progress indicators
- Status visualization
- Time-based progress tracking

#### **7. Empty States Enhancement**
- Enhanced empty state designs with helpful illustrations
- Contextual empty state messages
- Action buttons in empty states 