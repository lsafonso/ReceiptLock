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
│   └── SettingsView.swift        # Enhanced settings hierarchy
├── Managers/                     # Business logic
│   ├── NotificationManager.swift # Local notification handling
│   ├── CurrencyManager.swift     # Multi-currency support
│   ├── UserProfileManager.swift  # Profile management
│   ├── ReminderManager.swift     # Advanced reminder system
│   ├── DataBackupManager.swift   # Backup and sync
│   └── StorageManager.swift      # Storage optimization
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

8. **Accessibility**
   - VoiceOver labels
   - Dynamic Type support
   - Focus states

9. **Store Badge System**
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