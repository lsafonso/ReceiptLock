import SwiftUI
import AVFoundation

struct BarcodeScannerView: View {
    @StateObject private var scannerService = BarcodeScannerService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingFlashMenu = false
    @State private var scannedCodeDisplay: String?
    @State private var scannedTypeDisplay: String?
    
    var onCodeScanned: ((String, AVMetadataObject.ObjectType) -> Void)?
    
    init(onCodeScanned: ((String, AVMetadataObject.ObjectType) -> Void)? = nil) {
        self.onCodeScanned = onCodeScanned
    }
    
    var body: some View {
        ZStack {
            // Scanner preview
            if scannerService.isAuthorized {
                BarcodeScannerPreviewView(scannerService: scannerService)
                    .ignoresSafeArea()
                
                // Scanning overlay
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
            } else {
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
            scannerService.startScanning()
        }
        .onDisappear {
            scannerService.stopScanning()
            scannerService.resetScan()
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

