import Foundation
import AVFoundation
import CoreVideo
import UIKit
import SwiftUI
import Combine

class CameraService: NSObject, ObservableObject {
    static let shared = CameraService()
    
    @Published var isAuthorized = false
    @Published var isSessionRunning = false
    @Published var capturedImage: UIImage?
    @Published var error: CameraError?
    @Published var isCapturing = false
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    @Published var cameraPosition: AVCaptureDevice.Position = .back
    
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var currentCamera: AVCaptureDevice?
    private var currentCameraPosition: AVCaptureDevice.Position = .back
    
    // Camera configuration
    private let sessionPreset: AVCaptureSession.Preset = .photo
    private let photoCompressionQuality: Float = 0.9
    
    // Dedicated queue for session operations
    private let sessionQueue = DispatchQueue(label: "com.receiptlock.camera.session")
    private var isSetupInProgress = false
    private var startRetryCount = 0
    private let maxStartRetries = 5
    
    private override init() {
        super.init()
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    private func checkAuthorizationStatus() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if granted {
                        self?.setupCamera()
                    }
                }
            }
        case .denied, .restricted:
            isAuthorized = false
            error = .notAuthorized
        @unknown default:
            isAuthorized = false
            error = .unknown
        }
    }
    
    // MARK: - Camera Setup
    
    private func setupCamera(completion: ((Bool) -> Void)? = nil) {
        // Prevent multiple concurrent setups
        guard !isSetupInProgress else {
            completion?(false)
            return
        }
        
        // Run setup on dedicated session queue for thread safety
        sessionQueue.async { [weak self] in
            guard let self = self else {
                completion?(false)
                return
            }
            
            // Check if already configured
            if !self.session.inputs.isEmpty && !self.session.outputs.isEmpty {
                DispatchQueue.main.async {
                    self.isSetupInProgress = false
                    completion?(true)
                }
                return
            }
            
            DispatchQueue.main.async {
                self.isSetupInProgress = true
            }
            
            self.session.beginConfiguration()
            
            // Set session preset for high quality
            self.session.sessionPreset = self.sessionPreset
            
            // Add video input
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.currentCameraPosition) else {
                print("❌ Camera: Camera device not found")
                self.session.commitConfiguration()
                DispatchQueue.main.async {
                    self.error = .deviceNotFound
                    self.isSetupInProgress = false
                    completion?(false)
                }
                return
            }
            
            guard let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
                print("❌ Camera: Cannot create video input")
                self.session.commitConfiguration()
                DispatchQueue.main.async {
                    self.error = .deviceNotFound
                    self.isSetupInProgress = false
                    completion?(false)
                }
                return
            }
            
            if self.session.canAddInput(videoInput) {
                self.session.addInput(videoInput)
                self.currentCamera = videoDevice
                self.setupCameraSettings(for: videoDevice)
                print("✅ Camera: Video input added")
            } else {
                print("❌ Camera: Cannot add video input")
                self.session.commitConfiguration()
                DispatchQueue.main.async {
                    self.error = .inputError(CameraError.deviceNotFound)
                    self.isSetupInProgress = false
                    completion?(false)
                }
                return
            }
            
            // Add photo output
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
                self.setupPhotoOutput()
                print("✅ Camera: Photo output added")
            } else {
                print("❌ Camera: Cannot add photo output")
                self.session.commitConfiguration()
                DispatchQueue.main.async {
                    self.error = .inputError(CameraError.deviceNotFound)
                    self.isSetupInProgress = false
                    completion?(false)
                }
                return
            }
            
            self.session.commitConfiguration()
            
            // Verify setup was successful
            let setupSuccessful = !self.session.inputs.isEmpty && !self.session.outputs.isEmpty
            print("✅ Camera: Setup complete. Inputs: \(self.session.inputs.count), Outputs: \(self.session.outputs.count)")
            
            DispatchQueue.main.async {
                self.isSetupInProgress = false
                completion?(setupSuccessful)
            }
        }
    }
    
    private func setupCameraSettings(for device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            
            // Enable auto focus - check support first
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            
            // Enable auto exposure - check support first
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            
            // Enable auto white balance - check support first
            if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                device.whiteBalanceMode = .continuousAutoWhiteBalance
            }
            
            // Set high resolution - check support first
            if device.isLockingFocusWithCustomLensPositionSupported {
                device.setFocusModeLocked(lensPosition: 0.5)
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Error setting camera configuration: \(error)")
        }
    }
    
    private func setupPhotoOutput() {
        // Photo output configuration is done at capture time
        // No need to pre-configure settings
    }
    
    // MARK: - Session Control
    
    func startSession() {
        guard !session.isRunning else { 
            // Update state if already running
            DispatchQueue.main.async { [weak self] in
                self?.isSessionRunning = true
            }
            return 
        }
        
        // Check if session is configured on the session queue
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            let isConfigured = !self.session.inputs.isEmpty && !self.session.outputs.isEmpty
            
            if !isConfigured {
                // Session not configured, try to set it up
                DispatchQueue.main.async {
                    if self.isAuthorized {
                        print("🔧 Camera: Starting setup (attempt \(self.startRetryCount + 1)/\(self.maxStartRetries))")
                        self.startRetryCount += 1
                        
                        if self.startRetryCount > self.maxStartRetries {
                            self.error = .unknown
                            print("❌ Camera: Failed to start after \(self.maxStartRetries) attempts")
                            self.startRetryCount = 0
                            return
                        }
                        
                        self.setupCamera { [weak self] success in
                            guard let self = self else { return }
                            if success {
                                print("✅ Camera: Setup successful, starting session")
                                self.startRetryCount = 0
                                self.startSession() // Retry starting now that setup is complete
                            } else {
                                print("❌ Camera: Setup failed, retrying...")
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    self.startSession()
                                }
                            }
                        }
                    }
                }
                return
            }
            
            // Session is configured, reset retry count and start
            DispatchQueue.main.async {
                self.startRetryCount = 0
            }
            
            print("🚀 Camera: Starting session")
            self.session.startRunning()
            
            DispatchQueue.main.async {
                self.isSessionRunning = self.session.isRunning
                
                if self.session.isRunning {
                    print("✅ Camera: Session started successfully")
                } else {
                    print("❌ Camera: Session failed to start")
                    self.error = .unknown
                }
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if self.session.isRunning {
                self.session.stopRunning()
            }
            
            // Remove all inputs and outputs
            self.session.beginConfiguration()
            for input in self.session.inputs {
                self.session.removeInput(input)
            }
            for output in self.session.outputs {
                self.session.removeOutput(output)
            }
            self.session.commitConfiguration()
            
            DispatchQueue.main.async {
                self.isSessionRunning = false
            }
        }
    }
    
    func clearCapturedImage() {
        DispatchQueue.main.async { [weak self] in
            self?.capturedImage = nil
        }
    }
    
    // MARK: - Camera Control
    
    func switchCamera() {
        let newPosition: AVCaptureDevice.Position = currentCameraPosition == .back ? .front : .back
        
        guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else {
            error = .deviceNotFound
            return
        }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            
            // Remove current input
            if let currentInput = self.session.inputs.first {
                self.session.removeInput(currentInput)
            }
            
            // Add new input
            do {
                let newInput = try AVCaptureDeviceInput(device: newCamera)
                if self.session.canAddInput(newInput) {
                    self.session.addInput(newInput)
                    self.currentCamera = newCamera
                    self.currentCameraPosition = newPosition
                    self.setupCameraSettings(for: newCamera)
                    
                    DispatchQueue.main.async {
                        self.cameraPosition = newPosition
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = .inputError(error)
                }
            }
            
            self.session.commitConfiguration()
        }
    }
    
    func toggleFlash() {
        guard let device = currentCamera else { return }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                try device.lockForConfiguration()
                
                // Check if device supports flash and what modes are available
                if device.hasFlash {
                    let supportedModes = self.photoOutput.supportedFlashModes
                    var newMode: AVCaptureDevice.FlashMode = .off
                    
                    // Cycle through supported modes
                    switch self.flashMode {
                    case .off:
                        if supportedModes.contains(.on) {
                            newMode = .on
                        } else if supportedModes.contains(.auto) {
                            newMode = .auto
                        }
                    case .on:
                        if supportedModes.contains(.auto) {
                            newMode = .auto
                        } else {
                            newMode = .off
                        }
                    case .auto:
                        newMode = .off
                    @unknown default:
                        newMode = .off
                    }
                    
                    DispatchQueue.main.async {
                        self.flashMode = newMode
                    }
                }
                
                device.unlockForConfiguration()
            } catch {
                print("Error setting flash mode: \(error)")
            }
        }
    }
    
    func focusCamera(at point: CGPoint) {
        guard let device = currentCamera else { return }
        
        sessionQueue.async {
            do {
                try device.lockForConfiguration()
                
                // Check focus mode support before setting
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
                    device.focusPointOfInterest = point
                    device.focusMode = .autoFocus
                }
                
                // Check exposure mode support before setting
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.autoExpose) {
                    device.exposurePointOfInterest = point
                    device.exposureMode = .autoExpose
                }
                
                device.unlockForConfiguration()
            } catch {
                print("Error setting camera focus: \(error)")
            }
        }
    }
    
    func zoomCamera(to factor: CGFloat) {
        guard let device = currentCamera else { return }
        
        sessionQueue.async {
            let clampedFactor = max(1.0, min(factor, device.activeFormat.videoMaxZoomFactor))
            
            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = clampedFactor
                device.unlockForConfiguration()
            } catch {
                print("Error setting camera zoom: \(error)")
            }
        }
    }
    
    // MARK: - Photo Capture
    
    func capturePhoto() {
        guard isSessionRunning && !isCapturing else { return }
        
        isCapturing = true
        
        // Build valid AVCapturePhotoSettings
        var settings = AVCapturePhotoSettings()
        
        // Use JPEG codec if available (iOS 11+)
        if #available(iOS 11.0, *),
           photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
            settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        }
        
        // Enable high resolution if supported (iOS 16+)
        // Note: Deployment target is iOS 18.5, so we only need the modern API
        if photoOutput.maxPhotoDimensions.width > 0 && photoOutput.maxPhotoDimensions.height > 0 {
            settings.maxPhotoDimensions = photoOutput.maxPhotoDimensions
        }
        
        // Configure flash only if device supports it
        if photoOutput.isFlashScene, let device = currentCamera, device.hasFlash {
            // Check if the flash mode is supported before setting
            let supportedModes = photoOutput.supportedFlashModes
            if supportedModes.contains(flashMode) {
                settings.flashMode = flashMode
            }
        }
        
        // Optional preview format - use standard BGRA format for preview
        settings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        // Configure orientation
        if let photoOutputConnection = photoOutput.connection(with: .video) {
            if #available(iOS 17.0, *) {
                photoOutputConnection.videoRotationAngle = 0.0 // 0° = portrait
            } else {
                photoOutputConnection.videoOrientation = .portrait
            }
        }
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // MARK: - Image Processing
    
    func processCapturedImage(_ image: UIImage) -> UIImage? {
        // Enhance image for receipt scanning
        guard let cgImage = image.cgImage else { return image }
        
        let ciImage = CIImage(cgImage: cgImage)
        
        // Apply filters for better text recognition
        let filters: [CIFilter] = [
            // Enhance contrast
            CIFilter(name: "CIColorControls")?.then { filter in
                filter.setValue(ciImage, forKey: kCIInputImageKey)
                filter.setValue(1.1, forKey: kCIInputContrastKey)
                filter.setValue(0.0, forKey: kCIInputSaturationKey)
            },
            
            // Sharpen
            CIFilter(name: "CISharpenLuminance")?.then { filter in
                filter.setValue(ciImage, forKey: kCIInputImageKey)
                filter.setValue(0.5, forKey: kCIInputSharpnessKey)
            }
        ].compactMap { $0 }
        
        var processedImage = ciImage
        
        for filter in filters {
            if let outputImage = filter.outputImage {
                processedImage = outputImage
            }
        }
        
        // Convert back to UIImage
        let context = CIContext()
        if let cgImage = context.createCGImage(processedImage, from: processedImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        
        return image
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.isCapturing = false
            
            if let error = error {
                self?.error = .captureError(error)
                return
            }
            
            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else {
                self?.error = .invalidImage
                return
            }
            
            // Process the image for better receipt scanning
            let processedImage = self?.processCapturedImage(image) ?? image
            self?.capturedImage = processedImage
        }
    }
}

// MARK: - Camera Preview Layer

struct CameraPreviewView: UIViewRepresentable {
    let cameraService: CameraService
    
    func makeUIView(context: Context) -> CameraPreviewContainerView {
        let containerView = CameraPreviewContainerView()
        
        // Create preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: cameraService.session)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        // Configure preview layer connection orientation
        if let connection = previewLayer.connection {
            // Always set to portrait orientation for consistent display
            // On iPhones, camera sensor is typically mounted in landscape, so portrait requires 90° rotation
            if #available(iOS 17.0, *) {
                // Try 90 degrees first (typical for portrait on iPhone)
                if connection.isVideoRotationAngleSupported(90.0) {
                    connection.videoRotationAngle = 90.0 // Portrait on iPhone
                } else if connection.isVideoRotationAngleSupported(0.0) {
                    connection.videoRotationAngle = 0.0 // Fallback
                }
            } else {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
            }
            
            // Ensure connection is enabled
            if connection.isEnabled == false {
                connection.isEnabled = true
            }
        }
        
        containerView.previewLayer = previewLayer
        containerView.layer.addSublayer(previewLayer)
        
        // Ensure preview layer frame is set after a brief delay to allow view to layout
        DispatchQueue.main.async {
            if !containerView.bounds.isEmpty {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                previewLayer.frame = containerView.bounds
                CATransaction.commit()
            }
        }
        
        return containerView
    }
    
    func updateUIView(_ uiView: CameraPreviewContainerView, context: Context) {
        guard let previewLayer = uiView.previewLayer else { return }
        
        // Update frame when view bounds change
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        previewLayer.frame = uiView.bounds
        CATransaction.commit()
        
        // Update orientation when view updates - always keep portrait
        if let connection = previewLayer.connection {
            if #available(iOS 17.0, *) {
                if connection.isVideoRotationAngleSupported(0.0) {
                    connection.videoRotationAngle = 0.0 // Portrait
                }
            } else {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
            }
        }
    }
}

class CameraPreviewContainerView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let previewLayer = previewLayer, !bounds.isEmpty else { return }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        previewLayer.frame = bounds
        CATransaction.commit()
        
        // Update orientation when layout changes - always keep portrait
        // On iPhones, camera sensor is typically mounted in landscape, so portrait requires 90° rotation
        if let connection = previewLayer.connection {
            if #available(iOS 17.0, *) {
                if connection.isVideoRotationAngleSupported(90.0) {
                    connection.videoRotationAngle = 90.0 // Portrait on iPhone
                } else if connection.isVideoRotationAngleSupported(0.0) {
                    connection.videoRotationAngle = 0.0 // Fallback
                }
            } else {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
            }
        }
    }
}

// MARK: - Error Types

enum CameraError: Error, LocalizedError, Equatable {
    case notAuthorized
    case deviceNotFound
    case inputError(Error)
    case captureError(Error)
    case invalidImage
    case unknown
    
    static func == (lhs: CameraError, rhs: CameraError) -> Bool {
        switch (lhs, rhs) {
        case (.notAuthorized, .notAuthorized),
             (.deviceNotFound, .deviceNotFound),
             (.invalidImage, .invalidImage),
             (.unknown, .unknown):
            return true
        case (.inputError(let lhsError), .inputError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.captureError(let lhsError), .captureError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Camera access is required to take photos"
        case .deviceNotFound:
            return "Camera device not found"
        case .inputError(let error):
            return "Camera input error: \(error.localizedDescription)"
        case .captureError(let error):
            return "Photo capture error: \(error.localizedDescription)"
        case .invalidImage:
            return "Invalid image captured"
        case .unknown:
            return "Unknown camera error"
        }
    }
}

// MARK: - Helper Extension

extension CIFilter {
    func then(_ configure: (CIFilter) -> Void) -> CIFilter {
        configure(self)
        return self
    }
}
