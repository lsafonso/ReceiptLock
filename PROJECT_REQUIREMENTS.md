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

### 5. Dashboard (Home)
- **Warranty Summary Card**: Three-column display showing:
  - All devices (total count)
  - Valid warranties (active count)
  - Expired warranties (expired count)
- **Recent Appliances**: Latest 3 added appliances
- **Quick Actions**: Add new appliance button
- **Clean Design**: No navigation title, minimal interface

### 6. Appliance List
- **Search**: Text-based search across all fields
- **Filters**: All, Valid, Expired, Expiring Soon
- **Interactive Chips**: Animated filter selection with counts
- **Actions**: Edit, delete, share
- **Progress Indicators**: Visual warranty progress bars

### 7. Navigation Structure
- **Tab Bar**: 4 main sections
  - Home: Dashboard with warranty overview
  - Appliances: Complete appliance list
  - Add: Central floating action button
  - Profile: User settings and preferences

### 8. Notifications
- **Local Reminders**: Before warranty expiry
- **Configurable**: Default reminder days (7, 14, 30)
- **Smart Scheduling**: Only for future expiry dates
- **Permission Handling**: Request notification access

### 9. Settings (Profile)
- **Default Reminder Days**: Configurable (7, 14, 30 days)
- **Theme**: System, Light, Dark modes
- **Data Export**: ZIP with JSON + assets
- **Data Import**: Restore from exported data
- **Data Management**: Delete all data option

### 10. Share Functionality
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

## Technical Requirements

### Core Data
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
- [ ] All UI tests pass
- [ ] All unit tests pass
- [ ] Accessibility features work correctly
- [ ] Performance meets requirements

## Recent Updates
- **Design Transformation**: Converted from "ReceiptLock" to "Appliance Warranty Tracker"
- **Color Scheme**: Implemented muted green (`#336666`) as primary color
- **Navigation**: Simplified to 4-tab structure (Home, Appliances, Add, Profile)
- **Dashboard**: Removed promotional banner and navigation title
- **Icons**: Unified warranty summary icons to use consistent muted green
- **Categories**: Added 25+ appliance categories with smart selection
- **Interactions**: Enhanced with animations, haptic feedback, and modern UI patterns 