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
│   └── SettingsView.swift        # App settings and data management
├── Managers/                     # Business logic
│   └── NotificationManager.swift # Local notification handling
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

4. **OCR Integration**
   - Vision framework for text extraction
   - Automatic field suggestion
   - Image processing and storage

5. **File Management**
   - Local storage in Documents/receipts/
   - Image and PDF support
   - Automatic file cleanup on deletion

6. **Notifications**
   - Local notification scheduling
   - Configurable reminder days
   - Automatic scheduling on receipt save

7. **Settings**
   - Default reminder configuration
   - Theme selection
   - Export/Import functionality
   - Data deletion

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

**Key Dependencies:**
- SwiftUI for UI
- Core Data for persistence
- Vision for OCR
- PDFKit for PDF generation
- UserNotifications for local notifications
- PhotosUI for image selection
- FileManager for file storage

## Build Process

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0+ deployment target
- iPhone device or simulator

### Build Steps

1. **Clean Build**
   ```bash
   xcodebuild clean -project ReceiptLock.xcodeproj -scheme ReceiptLock
   ```

2. **Build for Simulator**
   ```bash
   xcodebuild build -project ReceiptLock.xcodeproj -scheme ReceiptLock -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'
   ```

3. **Run Tests**
   ```bash
   xcodebuild test -project ReceiptLock.xcodeproj -scheme ReceiptLock -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'
   ```

### Using the Build Script

The included `build.sh` script automates the build process:

```bash
./build.sh
```

This script will:
- Verify Xcode installation
- Clean previous builds
- Build for simulator
- Run unit tests
- Provide status feedback

## Testing

### Unit Tests
Run with `Cmd+U` in Xcode. Tests cover:
- Date calculation logic
- Expiry status determination
- Price formatting
- Warranty validation

### UI Tests
Run with `Cmd+Shift+U` in Xcode. Tests cover:
- App launch and navigation
- Tab switching
- Add receipt flow
- Settings navigation

## Common Issues and Solutions

### 1. Core Data Model Not Found
**Issue:** "Cannot find 'Receipt' in scope"
**Solution:** 
- Ensure ReceiptLock.xcdatamodeld is included in the target
- Clean build folder (Cmd+Shift+K)
- Rebuild project

### 2. Permission Issues
**Issue:** App crashes when accessing photos
**Solution:**
- Check Info.plist has proper usage descriptions
- Ensure permissions are requested at runtime

### 3. OCR Not Working
**Issue:** Vision framework errors
**Solution:**
- Ensure device/simulator supports Vision
- Check image format compatibility
- Verify Vision framework is linked

### 4. Notifications Not Appearing
**Issue:** Local notifications not showing
**Solution:**
- Check notification permissions
- Verify notification scheduling logic
- Test on physical device (simulator limitations)

## File Storage

Receipt files are stored in:
```
Documents/receipts/
├── receipt-uuid-1.jpg
├── receipt-uuid-2.pdf
└── ...
```

## Permissions Required

The app requests these permissions:
- **Notifications**: For warranty expiry reminders
- **Photo Library**: For selecting receipt images
- **Camera**: For capturing receipt images (optional)

## Error Handling

The app includes comprehensive error handling for:
- Core Data operations
- File I/O operations
- OCR processing
- Notification scheduling
- User input validation

All errors are logged and user-friendly messages are displayed.

## Performance Considerations

- Images are compressed before storage
- OCR processing is asynchronous
- Core Data operations are performed on background queues
- File operations include proper error handling
- Memory management for large images

## Security

- All data is stored locally
- No network requests
- File access is sandboxed
- No sensitive data logging

## Next Steps

To extend the app, consider:
1. Adding iCloud sync
2. Implementing advanced OCR
3. Adding receipt categorization
4. Creating widgets
5. Adding Apple Watch support
6. Implementing cloud backup

## Support

For build issues:
1. Check Xcode version compatibility
2. Verify iOS deployment target
3. Clean and rebuild project
4. Check device/simulator compatibility

For runtime issues:
1. Check console logs
2. Verify permissions
3. Test on physical device
4. Check Core Data model version 