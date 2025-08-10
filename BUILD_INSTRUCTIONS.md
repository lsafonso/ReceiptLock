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
│   ├── DashboardView.swift       # Dashboard with upcoming/expired receipts
│   ├── ReceiptListView.swift     # Full receipt list with search/filter
│   ├── AddReceiptView.swift      # Add new receipt with OCR
│   ├── EditReceiptView.swift     # Edit existing receipt
│   ├── ReceiptDetailView.swift   # Detailed receipt view
│   ├── ReceiptRowView.swift      # Receipt list item component
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
   - Receipt entity with all required fields
   - Automatic expiry date calculation
   - Lightweight migrations support

2. **Dashboard View**
   - Upcoming expirations (30 days)
   - Expired warranties
   - Recent receipts (5 most recent)

3. **Receipt Management**
   - Create, edit, delete receipts
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
   - Automatic scheduling on receipt save

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

### 🔧 Technical Implementation

**Core Data Model:**
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

**Settings Architecture:**
The enhanced settings use a modular approach with:
- `SettingsSection` component for consistent section styling
- `SettingsRow` component for uniform row presentation
- State management through various managers
- Sheet presentations for detailed configuration views 