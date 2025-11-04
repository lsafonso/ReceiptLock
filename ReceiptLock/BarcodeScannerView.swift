import SwiftUI
import AVFoundation

struct BarcodeScannerView: View {
    @StateObject private var scannerService = BarcodeScannerService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingFlashMenu = false
    @State private var scannedCodeDisplay: String?
    @State private var scannedTypeDisplay: String?
    @State private var manualBarcodeEntry: String = ""
    @State private var showingManualEntry = false
    
    var onCodeScanned: ((String, AVMetadataObject.ObjectType) -> Void)?
    
    init(onCodeScanned: ((String, AVMetadataObject.ObjectType) -> Void)? = nil) {
        self.onCodeScanned = onCodeScanned
    }
    
    private var isSimulatorError: Bool {
        if case .simulatorNotSupported = scannerService.error {
            return true
        }
        return false
    }
    
    var body: some View {
        ZStack {
            // Background color - should not be visible if camera works
            Color.black
                .ignoresSafeArea()
            
            // Check for simulator error
            if isSimulatorError {
                simulatorErrorView
            } else if scannerService.isAuthorized && scannerService.isSessionRunning {
                // Scanner preview
                BarcodeScannerPreviewView(scannerService: scannerService)
                    .ignoresSafeArea()
            } else if scannerService.isAuthorized {
                // Show loading state while session is starting
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Text("Starting camera...")
                        .foregroundColor(.white)
                        .padding(.top)
                }
            }
            
            // Scanning overlay - only show when authorized and not simulator
            if scannerService.isAuthorized && !isSimulatorError {
                scanningOverlay
                
                // Top controls
                VStack {
                    HStack {
                        Button("Cancel") {
                            scannerService.stopScanning()
                            dismiss()
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(.black.opacity(0.6))
                        .cornerRadius(12)
                        
                        Spacer()
                        
                        Button(action: {
                            scannerService.switchCamera()
                        }) {
                            Image(systemName: "camera.rotate")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(.black.opacity(0.6))
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Bottom instructions
                    VStack(spacing: 16) {
                        if let code = scannedCodeDisplay, let type = scannedTypeDisplay {
                            // Success state
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.green)
                                
                                Text("Scanned Successfully!")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text(type)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text(code)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(.black.opacity(0.5))
                                    .cornerRadius(8)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .background(.black.opacity(0.7))
                            .cornerRadius(16)
                        } else {
                            // Scanning instructions
                            VStack(spacing: 8) {
                                Text("Position barcode or QR code within the frame")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                
                                Text("Scanning will happen automatically")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(.black.opacity(0.6))
                            .cornerRadius(20)
                        }
                    }
                    .padding(.bottom, 50)
                }
            } else if !isSimulatorError {
                CameraPermissionView()
            }
        }
        .onAppear {
            scannerService.onCodeScanned = { code, type in
                scannedCodeDisplay = code
                scannedTypeDisplay = type.displayName
                
                // Call external handler if provided
                onCodeScanned?(code, type)
            }
            
            // Ensure session is set up and start scanning (only if not simulator)
            if scannerService.isAuthorized && !isSimulatorError {
                scannerService.startScanning()
            }
        }
        .onChange(of: scannerService.isAuthorized) { oldValue, newValue in
            if newValue && !isSimulatorError {
                scannerService.startScanning()
            }
        }
        .onDisappear {
            scannerService.stopScanning()
            scannerService.resetScan()
        }
    }
    
    // MARK: - Simulator Error View
    private var simulatorErrorView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("Camera Not Available")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("The camera is not available in the iOS Simulator. Please use a physical device to scan barcodes, or enter the barcode manually.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            VStack(spacing: 12) {
                Button(action: {
                    showingManualEntry = true
                }) {
                    HStack {
                        Image(systemName: "keyboard")
                        Text("Enter Barcode Manually")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.primary)
                    .cornerRadius(12)
                }
                
                Button("Cancel") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .sheet(isPresented: $showingManualEntry) {
            manualBarcodeEntryView
        }
    }
    
    // MARK: - Manual Barcode Entry View
    private var manualBarcodeEntryView: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter Barcode or QR Code")
                        .font(.headline)
                        .foregroundColor(AppTheme.text)
                    
                    TextField("Barcode or QR code", text: $manualBarcodeEntry)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.default)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
                .padding()
                
                Button(action: {
                    if !manualBarcodeEntry.isEmpty {
                        // Use a default barcode type (Code128 is common)
                        onCodeScanned?(manualBarcodeEntry, .code128)
                        dismiss()
                    }
                }) {
                    Text("Use This Barcode")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(manualBarcodeEntry.isEmpty ? Color.gray : AppTheme.primary)
                        .cornerRadius(12)
                }
                .disabled(manualBarcodeEntry.isEmpty)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .background(AppTheme.background)
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showingManualEntry = false
                    }
                }
            }
        }
    }
    
    private var scanningOverlay: some View {
        GeometryReader { geometry in
            let frameWidth = geometry.size.width * 0.7
            let frameHeight = frameWidth * 0.7 // Square-ish frame
            let frameX = (geometry.size.width - frameWidth) / 2
            let frameY = (geometry.size.height - frameHeight) / 2
            
            ZStack {
                // Dimmed overlay
                Path { path in
                    path.addRect(CGRect(x: 0, y: 0, width: geometry.size.width, height: geometry.size.height))
                }
                .fill(.black.opacity(0.5))
                
                // Clear scanning area
                Path { path in
                    path.addRect(CGRect(x: frameX, y: frameY, width: frameWidth, height: frameHeight))
                }
                .fill(.clear)
                .blendMode(.destinationOut)
                
                // Scanning frame border
                Path { path in
                    path.addRect(CGRect(x: frameX, y: frameY, width: frameWidth, height: frameHeight))
                }
                .stroke(Color.white, style: StrokeStyle(lineWidth: 2))
                
                // Corner indicators
                let cornerSize: CGFloat = 25
                let cornerThickness: CGFloat = 4
                
                // Top-left corner
                Path { path in
                    path.move(to: CGPoint(x: frameX, y: frameY + cornerSize))
                    path.addLine(to: CGPoint(x: frameX, y: frameY))
                    path.addLine(to: CGPoint(x: frameX + cornerSize, y: frameY))
                }
                .stroke(Color.green, lineWidth: cornerThickness)
                
                // Top-right corner
                Path { path in
                    path.move(to: CGPoint(x: frameX + frameWidth - cornerSize, y: frameY))
                    path.addLine(to: CGPoint(x: frameX + frameWidth, y: frameY))
                    path.addLine(to: CGPoint(x: frameX + frameWidth, y: frameY + cornerSize))
                }
                .stroke(Color.green, lineWidth: cornerThickness)
                
                // Bottom-left corner
                Path { path in
                    path.move(to: CGPoint(x: frameX, y: frameY + frameHeight - cornerSize))
                    path.addLine(to: CGPoint(x: frameX, y: frameY + frameHeight))
                    path.addLine(to: CGPoint(x: frameX + cornerSize, y: frameY + frameHeight))
                }
                .stroke(Color.green, lineWidth: cornerThickness)
                
                // Bottom-right corner
                Path { path in
                    path.move(to: CGPoint(x: frameX + frameWidth - cornerSize, y: frameY + frameHeight))
                    path.addLine(to: CGPoint(x: frameX + frameWidth, y: frameY + frameHeight))
                    path.addLine(to: CGPoint(x: frameX + frameWidth, y: frameY + frameHeight - cornerSize))
                }
                .stroke(Color.green, lineWidth: cornerThickness)
            }
            .compositingGroup()
        }
    }
}

#Preview {
    BarcodeScannerView()
}

