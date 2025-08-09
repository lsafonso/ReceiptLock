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
- imageData: Data (optional)
- ocrProcessed: Bool
- ocrText: String (optional)
- pdfURL: String (optional)
- pdfPageCount: Int16 (optional)
- pdfProcessed: Bool (optional)
```

**Receipt Scanning & OCR Architecture:**
```swift
CameraService: AVFoundation-based camera management
├── Camera authorization and setup
├── Photo capture with receipt-optimized settings
├── Image preprocessing for better OCR results
└── Flash and zoom controls

OCRService: Vision framework integration
├── Text recognition with high accuracy
├── Smart data extraction patterns
├── Progress tracking and error handling
└── ReceiptData structure for extracted information

ImageStorageManager: File system management
├── Optimized image compression and storage
├── Thumbnail generation
├── Storage usage monitoring
└── Automatic cleanup of orphaned files

ImageEditorView: Built-in image editing
├── Brightness, contrast, saturation filters
├── Receipt-specific image enhancement
└── Real-time preview for OCR optimization
```

**OCR Data Extraction Capabilities:**
```swift
ReceiptData Structure:
├── title: Product/description extraction
├── store: Store name and branding detection
├── price: Multiple price pattern recognition
├── purchaseDate: Various date format parsing
├── warrantyInfo: Warranty terms and conditions
├── taxAmount: Tax calculation extraction
├── totalAmount: Total payment amount
├── paymentMethod: Payment type detection
├── receiptNumber: Transaction ID extraction
├── storeAddress: Location information
├── storePhone: Contact number extraction
├── storeWebsite: Web presence detection
└── rawText: Complete OCR text for review
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

## PDF Processing & OCR Features

### PDF Document Support
- **Multi-format Support**: Handle both text-based and image-based PDFs
- **Page Conversion**: Convert PDF pages to high-resolution images for OCR
- **Text Extraction**: Direct text extraction from PDF documents
- **OCR Enhancement**: Process PDF images with Vision framework for better accuracy
- **Progress Tracking**: Real-time progress indication during PDF processing
- **File Validation**: Check PDF integrity and file size limits (50MB max)

### PDF Processing Workflow
1. **File Selection**: Import PDF documents via document picker
2. **Validation**: Check file format, size, and integrity
3. **Text Extraction**: Attempt direct text extraction from PDF
4. **Image Conversion**: Convert PDF pages to images for OCR processing
5. **OCR Processing**: Apply Vision framework to extracted images
6. **Data Combination**: Merge direct text with OCR results
7. **Results Display**: Show extracted data for user review

### PDF Service Architecture
```swift
PDFService: PDF processing and OCR integration
├── PDF validation and metadata extraction
├── Text extraction from PDF documents
├── Page-to-image conversion for OCR
├── Progress tracking and error handling
├── File size and format validation
└── Integration with existing OCR pipeline
```

## Camera Integration Features

### Receipt-Optimized Camera Settings
- **High Resolution**: Photo quality preset for optimal OCR results
- **Auto-Focus**: Tap-to-focus for precise receipt capture
- **Flash Control**: Manual flash settings (Off/On/Auto)
- **Zoom Support**: Pinch-to-zoom for detailed text capture
- **Receipt Guide**: Visual overlay for optimal positioning
- **Image Enhancement**: Automatic preprocessing for better text recognition

### Camera Workflow
1. **Authorization**: Request camera permissions on first use
2. **Setup**: Initialize camera with receipt-optimized settings
3. **Capture**: High-quality photo with progress indication
4. **Preview**: Review captured image before processing
5. **OCR**: Automatic text extraction with progress tracking
6. **Results**: Display extracted data for user review and application

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
- Check image quality and preprocessing
- Verify OCR text extraction patterns

### 4. Camera Permission Issues
**Issue:** Camera access denied
**Solution:**
- Check Info.plist has camera usage description
- Request permissions at runtime
- Guide user to Settings if denied
- Test on physical device (simulator limitations)

### 5. Notifications Not Appearing
**Issue:** Local notifications not showing
**Solution:**
- Check notification permissions
- Verify notification scheduling logic
- Test on physical device (simulator limitations)

## OCR Processing Workflow

### Text Extraction Process
1. **Image Preprocessing**: Enhance contrast, sharpen text, optimize for OCR
2. **Vision Framework**: Use VNRecognizeTextRequest for high-accuracy text recognition
3. **Language Support**: English language correction and recognition
4. **Progress Tracking**: Real-time progress updates during processing
5. **Error Handling**: Graceful fallback for failed OCR attempts

### Smart Data Extraction
- **Pattern Recognition**: Multiple regex patterns for different data types
- **Context Awareness**: Intelligent field mapping based on receipt structure
- **Validation**: Verify extracted data against expected formats
- **Auto-fill Logic**: Smart field population with user confirmation
- **Fallback Handling**: Manual entry when OCR extraction fails

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

## Image Editing & Enhancement

### Built-in Image Editor
- **Filter Controls**: Brightness, contrast, saturation adjustment
- **Receipt Optimization**: Pre-configured settings for better OCR results
- **Real-time Preview**: Instant feedback on image adjustments
- **Quality Preservation**: Maintain image quality for optimal text recognition
- **Batch Processing**: Apply enhancements to multiple images

### Image Storage Optimization
- **Compression**: JPEG compression with quality control (0.8)
- **Resizing**: Automatic resizing for large images (max 2048px)
- **Thumbnail Generation**: Fast loading of receipt lists
- **Storage Monitoring**: Track disk usage and cleanup orphaned files

## Performance Considerations

- Images are compressed before storage
- OCR processing is asynchronous
- Core Data operations are performed on background queues
- File operations include proper error handling
- Memory management for large images
- Camera capture optimization for receipt scanning

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