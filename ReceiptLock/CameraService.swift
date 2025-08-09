import Foundation
import AVFoundation
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
    
    private func setupCamera() {
        session.beginConfiguration()
        
        // Set session preset for high quality
        session.sessionPreset = sessionPreset
        
        // Add video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            error = .deviceNotFound
            session.commitConfiguration()
            return
        }
        
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
            currentCamera = videoDevice
            setupCameraSettings(for: videoDevice)
        } else {
            error = .inputError(CameraError.deviceNotFound)
            session.commitConfiguration()
            return
        }
        
        // Add photo output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            setupPhotoOutput()
        } else {
            error = .inputError(CameraError.deviceNotFound)
            session.commitConfiguration()
            return
        }
        
        session.commitConfiguration()
    }
    
    private func setupCameraSettings(for device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            
            // Enable auto focus
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            
            // Enable auto exposure
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            
            // Enable auto white balance
            if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                device.whiteBalanceMode = .continuousAutoWhiteBalance
            }
            
            // Set high resolution
            if device.isLockingFocusWithCustomLensPositionSupported {
                device.setFocusModeLocked(lensPosition: 0.5)
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Error setting camera configuration: \(error)")
        }
    }
    
    private func setupPhotoOutput() {
        // Configure photo output for high quality
        photoOutput.setPreparedPhotoSettingsArray([
            AVCapturePhotoSettings(format: [
                AVVideoCompressionPropertiesKey: [
                    AVVideoQualityKey: photoCompressionQuality
                ]
            ])
        ], completionHandler: nil)
    }
    
    // MARK: - Session Control
    
    func startSession() {
        guard !session.isRunning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = true
            }
        }
    }
    
    func stopSession() {
        guard session.isRunning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = false
            }
        }
    }
    
    // MARK: - Camera Control
    
    func switchCamera() {
        let newPosition: AVCaptureDevice.Position = currentCameraPosition == .back ? .front : .back
        
        guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else {
            error = .deviceNotFound
            return
        }
        
        session.beginConfiguration()
        
        // Remove current input
        if let currentInput = session.inputs.first {
            session.removeInput(currentInput)
        }
        
        // Add new input
        do {
            let newInput = try AVCaptureDeviceInput(device: newCamera)
            if session.canAddInput(newInput) {
                session.addInput(newInput)
                currentCamera = newCamera
                currentCameraPosition = newPosition
                cameraPosition = newPosition
                setupCameraSettings(for: newCamera)
            }
        } catch {
            self.error = .inputError(error)
        }
        
        session.commitConfiguration()
    }
    
    func toggleFlash() {
        guard let device = currentCamera else { return }
        
        do {
            try device.lockForConfiguration()
            
            if device.hasFlash {
                switch flashMode {
                case .off:
                    flashMode = .on
                case .on:
                    flashMode = .auto
                case .auto:
                    flashMode = .off
                @unknown default:
                    flashMode = .off
                }
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Error setting flash mode: \(error)")
        }
    }
    
    func focusCamera(at point: CGPoint) {
        guard let device = currentCamera else { return }
        
        do {
            try device.lockForConfiguration()
            
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = point
                device.focusMode = .autoFocus
            }
            
            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = point
                device.exposureMode = .autoExpose
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Error setting camera focus: \(error)")
        }
    }
    
    func zoomCamera(to factor: CGFloat) {
        guard let device = currentCamera else { return }
        
        let clampedFactor = max(1.0, min(factor, device.activeFormat.videoMaxZoomFactor))
        
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = clampedFactor
            device.unlockForConfiguration()
        } catch {
            print("Error setting camera zoom: \(error)")
        }
    }
    
    // MARK: - Photo Capture
    
    func capturePhoto() {
        guard isSessionRunning && !isCapturing else { return }
        
        isCapturing = true
        
        let settings = AVCapturePhotoSettings()
        
        // Configure flash
        if let device = currentCamera, device.hasFlash {
            settings.flashMode = flashMode
        }
        
        // Configure quality settings
        // Note: AVCapturePhotoSettings automatically uses the best available codec
        
        // Configure compression
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
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: cameraService.session)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.frame = view.bounds
        
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
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
