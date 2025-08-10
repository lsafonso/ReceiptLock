import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var cameraService = CameraService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingImagePreview = false
    @State private var showingCameraGuide = false
    @State private var zoomLevel: CGFloat = 1.0
    @State private var showingFlashMenu = false
    
    var body: some View {
        ZStack {
            // Camera preview
            if cameraService.isAuthorized {
                CameraPreviewView(cameraService: cameraService)
                    .ignoresSafeArea()
                    .onTapGesture { location in
                        cameraService.focusCamera(at: location)
                    }
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let newZoom = zoomLevel * value
                                cameraService.zoomCamera(to: newZoom)
                            }
                            .onEnded { _ in
                                // Reset zoom level for next gesture
                                zoomLevel = 1.0
                            }
                    )
                
                // Camera guide overlay
                if showingCameraGuide {
                    CameraGuideOverlay()
                }
                
                // Receipt frame guide
                if !showingCameraGuide {
                    ReceiptFrameGuide()
                }
            } else {
                CameraPermissionView()
            }
            
            // Camera controls overlay
            VStack {
                // Top controls
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(.black.opacity(0.6))
                    .cornerRadius(12)
                    
                    Spacer()
                    
                    // Flash control
                    Button(action: {
                        cameraService.toggleFlash()
                    }) {
                        Image(systemName: flashIcon)
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(.black.opacity(0.6))
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        showingCameraGuide.toggle()
                    }) {
                        Image(systemName: "questionmark.circle")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(.black.opacity(0.6))
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        cameraService.switchCamera()
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
                
                // Bottom controls
                VStack(spacing: 20) {
                    // Camera guide text
                    if !showingCameraGuide {
                        VStack(spacing: 8) {
                            Text("Position receipt within the frame")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.black.opacity(0.6))
                                .cornerRadius(20)
                            
                            Text("Pinch to zoom • Tap to focus")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 4)
                                .background(.black.opacity(0.4))
                                .cornerRadius(16)
                        }
                    }
                    
                    HStack {
                        Spacer()
                        
                        // Capture button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                cameraService.capturePhoto()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 80, height: 80)
                                
                                Circle()
                                    .stroke(.black.opacity(0.3), lineWidth: 4)
                                    .frame(width: 80, height: 80)
                                
                                if cameraService.isCapturing {
                                    ProgressView()
                                        .scaleEffect(1.2)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                }
                            }
                        }
                        .disabled(!cameraService.isSessionRunning || cameraService.isCapturing)
                        .scaleEffect(cameraService.isCapturing ? 0.9 : 1.0)
                        
                        Spacer()
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            cameraService.startSession()
        }
        .onDisappear {
            cameraService.stopSession()
        }
        .onChange(of: cameraService.capturedImage) { oldValue, newValue in
            if newValue != nil {
                showingImagePreview = true
            }
        }
        .onChange(of: cameraService.error) { oldValue, newValue in
            if newValue != nil {
                // Handle camera errors
                print("Camera error: \(newValue?.localizedDescription ?? "Unknown error")")
            }
        }
        .sheet(isPresented: $showingImagePreview) {
            if let capturedImage = cameraService.capturedImage {
                ImagePreviewView(image: capturedImage)
            }
        }
    }
    
    private var flashIcon: String {
        switch cameraService.flashMode {
        case .off:
            return "bolt.slash"
        case .on:
            return "bolt.fill"
        case .auto:
            return "bolt.badge.a"
        @unknown default:
            return "bolt.slash"
        }
    }
}

struct ReceiptFrameGuide: View {
    var body: some View {
        GeometryReader { geometry in
            let frameWidth = geometry.size.width * 0.8
            let frameHeight = frameWidth * 1.4 // Receipt aspect ratio
            let frameX = (geometry.size.width - frameWidth) / 2
            let frameY = (geometry.size.height - frameHeight) / 2
            
            Path { path in
                path.addRect(CGRect(x: frameX, y: frameY, width: frameWidth, height: frameHeight))
            }
            .stroke(Color.white, style: StrokeStyle(lineWidth: 2, dash: [10, 5]))
            
            // Corner indicators
            let cornerSize: CGFloat = 20
            let cornerThickness: CGFloat = 3
            
            // Top-left corner
            Path { path in
                path.move(to: CGPoint(x: frameX, y: frameY + cornerSize))
                path.addLine(to: CGPoint(x: frameX, y: frameY))
                path.addLine(to: CGPoint(x: frameX + cornerSize, y: frameY))
            }
            .stroke(Color.white, lineWidth: cornerThickness)
            
            // Top-right corner
            Path { path in
                path.move(to: CGPoint(x: frameX + frameWidth - cornerSize, y: frameY))
                path.addLine(to: CGPoint(x: frameX + frameWidth, y: frameY))
                path.addLine(to: CGPoint(x: frameX + frameWidth, y: frameY + cornerSize))
            }
            .stroke(Color.white, lineWidth: cornerThickness)
            
            // Bottom-left corner
            Path { path in
                path.move(to: CGPoint(x: frameX, y: frameY + frameHeight - cornerSize))
                path.addLine(to: CGPoint(x: frameX, y: frameY + frameHeight))
                path.addLine(to: CGPoint(x: frameX + cornerSize, y: frameY + frameHeight))
            }
            .stroke(Color.white, lineWidth: cornerThickness)
            
            // Bottom-right corner
            Path { path in
                path.move(to: CGPoint(x: frameX + frameWidth - cornerSize, y: frameY + frameHeight))
                path.addLine(to: CGPoint(x: frameX + frameWidth, y: frameY + frameHeight))
                path.addLine(to: CGPoint(x: frameX + frameWidth, y: frameY + frameHeight - cornerSize))
            }
            .stroke(Color.white, lineWidth: cornerThickness)
        }
    }
}

struct CameraGuideOverlay: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                
                Text("Receipt Scanning Tips")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 12) {
                    TipRow(icon: "1.circle.fill", text: "Ensure good lighting")
                    TipRow(icon: "2.circle.fill", text: "Keep receipt flat and steady")
                    TipRow(icon: "3.circle.fill", text: "Include all text within frame")
                    TipRow(icon: "4.circle.fill", text: "Avoid shadows and glare")
                }
                .padding()
                .background(.black.opacity(0.7))
                .cornerRadius(12)
            }
            .padding()
            .background(.black.opacity(0.8))
            .cornerRadius(16)
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title3)
            
            Text(text)
                .foregroundColor(.white)
                .font(.body)
            
            Spacer()
        }
    }
}

struct CameraPermissionView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Camera Access Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("To take photos of receipts, please allow camera access in Settings.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct ImagePreviewView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddReceipt = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                VStack(spacing: 16) {
                    Button("Use This Photo") {
                        showingAddReceipt = true
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    
                    Button("Retake Photo") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .navigationTitle("Photo Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddReceipt) {
            AddReceiptView(selectedImage: image)
        }
    }
}

#Preview {
    CameraView()
}
