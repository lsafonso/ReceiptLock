# ReceiptLock

A comprehensive iOS app for managing receipts and warranty information with OCR capabilities, local notifications, and data export/import features.

## Features

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
- **PDF Support**: Import and process PDF documents
- **OCR Results Management**: Review and selectively apply extracted data

### Dashboard
- **Upcoming Expirations**: Shows warranties expiring within 30 days
- **Expired Warranties**: Displays expired warranties
- **Recent Receipts**: Shows the 5 most recently added receipts

### Receipt List
- **Search & Filter**: Search by title/store and filter by status (All, Active, Expired, Expiring Soon)
- **Swipe to Delete**: Easy deletion with associated file cleanup
- **Navigation**: Tap to view detailed receipt information

### Settings
- **Notification Preferences**: Configure default reminder days (1-90 days)
- **Theme Selection**: System, Light, or Dark theme
- **Data Management**: Export/Import functionality and data deletion
- **About Section**: App version and legal links

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
│   │   └── SettingsView.swift
│   ├── Managers/                     # Business logic
│   │   └── NotificationManager.swift
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

- Cloud sync with iCloud
- Multiple currency support
- Enhanced OCR with machine learning
- Receipt categorization
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