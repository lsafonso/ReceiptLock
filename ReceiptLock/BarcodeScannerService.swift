import Foundation
import AVFoundation
import UIKit
import SwiftUI
import Combine

class BarcodeScannerService: NSObject, ObservableObject {
    static let shared = BarcodeScannerService()
    
    @Published var isAuthorized = false
    @Published var isSessionRunning = false
    @Published var scannedCode: String?
    @Published var scannedCodeType: AVMetadataObject.ObjectType?
    @Published var error: BarcodeScannerError?
    @Published var isScanning = false
    
    let session = AVCaptureSession()
    private let metadataOutput = AVCaptureMetadataOutput()
    private var currentCamera: AVCaptureDevice?
    private var currentCameraPosition: AVCaptureDevice.Position = .back
    
    // Dedicated queue for session operations
    private let sessionQueue = DispatchQueue(label: "com.receiptlock.barcode.session")
    private var isSetupInProgress = false
    private var startRetryCount = 0
    private let maxStartRetries = 5
    
    // Supported barcode types
    var supportedMetadataTypes: [AVMetadataObject.ObjectType] {
        return [
            .qr,
            .ean13,
            .ean8,
            .code128,
            .code39,
            .code93,
            .upce,
            .pdf417,
            .aztec,
            .dataMatrix
        ]
    }
    
    var onCodeScanned: ((String, AVMetadataObject.ObjectType) -> Void)?
    
    private override init() {
        super.init()
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    private func checkAuthorizationStatus() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            setupScanner()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if granted {
                        self?.setupScanner()
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
    
    // MARK: - Scanner Setup
    
    private func setupScanner(completion: ((Bool) -> Void)? = nil) {
        // Prevent multiple setups
        guard !isSetupInProgress else {
            completion?(false)
            return
        }
        
        // Check if already configured on session queue
        sessionQueue.async { [weak self] in
            guard let self = self else {
                completion?(false)
                return
            }
            
            if !self.session.inputs.isEmpty && !self.session.outputs.isEmpty {
                // Already configured
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
            
            // Remove existing inputs/outputs if any
            self.session.inputs.forEach { self.session.removeInput($0) }
            self.session.outputs.forEach { self.session.removeOutput($0) }
            
            // Set session preset for barcode scanning
            if self.session.canSetSessionPreset(.high) {
                self.session.sessionPreset = .high
            } else {
                self.session.sessionPreset = .medium
            }
            
            // Add video input
            // Try to get the camera device - check authorization first
            let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
            guard authStatus == .authorized else {
                print("❌ BarcodeScanner: Camera not authorized. Status: \(authStatus.rawValue)")
                self.session.commitConfiguration()
                DispatchQueue.main.async {
                    self.error = .notAuthorized
                    self.isSetupInProgress = false
                    completion?(false)
                }
                return
            }
            
            // Try to discover available camera devices first, then fallback to default
            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera],
                mediaType: .video,
                position: self.currentCameraPosition
            )
            
            let videoDevice = discoverySession.devices.first ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.currentCameraPosition)
            
            guard let videoDevice = videoDevice else {
                // Log available devices for debugging
                let allDevices = AVCaptureDevice.DiscoverySession(
                    deviceTypes: [.builtInWideAngleCamera],
                    mediaType: .video,
                    position: .unspecified
                ).devices
                print("❌ BarcodeScanner: Camera device not found. Total cameras: \(allDevices.count), Position requested: \(self.currentCameraPosition == .back ? "back" : "front")")
                self.session.commitConfiguration()
                DispatchQueue.main.async {
                    self.error = .deviceNotFound
                    self.isSetupInProgress = false
                    completion?(false)
                }
                return
            }
            
            print("✅ BarcodeScanner: Found camera device: \(videoDevice.localizedName)")
            
            do {
                let videoInput = try AVCaptureDeviceInput(device: videoDevice)
                
                if self.session.canAddInput(videoInput) {
                    self.session.addInput(videoInput)
                    self.currentCamera = videoDevice
                    print("✅ BarcodeScanner: Video input added")
                } else {
                    print("❌ BarcodeScanner: Cannot add video input")
                    self.session.commitConfiguration()
                    DispatchQueue.main.async {
                        self.error = .inputError(BarcodeScannerError.deviceNotFound)
                        self.isSetupInProgress = false
                        completion?(false)
                    }
                    return
                }
            } catch {
                print("❌ BarcodeScanner: Error creating video input: \(error.localizedDescription)")
                self.session.commitConfiguration()
                DispatchQueue.main.async {
                    self.error = .inputError(error)
                    self.isSetupInProgress = false
                    completion?(false)
                }
                return
            }
            
            // Add metadata output
            if self.session.canAddOutput(self.metadataOutput) {
                self.session.addOutput(self.metadataOutput)
                self.metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                self.metadataOutput.metadataObjectTypes = self.supportedMetadataTypes
                
                // Configure metadata output connection
                if let connection = self.metadataOutput.connection(with: .video) {
                    if connection.isVideoOrientationSupported {
                        if #available(iOS 17.0, *) {
                            connection.videoRotationAngle = 0.0
                        } else {
                            connection.videoOrientation = .portrait
                        }
                    }
                }
                print("✅ BarcodeScanner: Metadata output added")
            } else {
                print("❌ BarcodeScanner: Cannot add metadata output")
                self.session.commitConfiguration()
                DispatchQueue.main.async {
                    self.error = .outputError
                    self.isSetupInProgress = false
                    completion?(false)
                }
                return
            }
            
            self.session.commitConfiguration()
            
            // Verify setup was successful
            let setupSuccessful = !self.session.inputs.isEmpty && !self.session.outputs.isEmpty
            print("✅ BarcodeScanner: Setup complete. Inputs: \(self.session.inputs.count), Outputs: \(self.session.outputs.count)")
            
            DispatchQueue.main.async {
                self.isSetupInProgress = false
                completion?(setupSuccessful)
            }
        }
    }
    
    // MARK: - Session Control
    
    func startScanning() {
        guard !session.isRunning else { 
            // Already running, but update state
            DispatchQueue.main.async { [weak self] in
                self?.isSessionRunning = true
                self?.isScanning = true
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
                    // Double-check authorization status
                    let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
                    if authStatus == .authorized {
                        // Update isAuthorized to match actual status
                        self.isAuthorized = true
                        
                        print("🔧 BarcodeScanner: Starting setup (attempt \(self.startRetryCount + 1)/\(self.maxStartRetries))")
                        
                        if self.startRetryCount >= self.maxStartRetries {
                            self.error = .unknown
                            print("❌ BarcodeScanner: Failed to start after \(self.maxStartRetries) attempts")
                            self.startRetryCount = 0
                            return
                        }
                        
                        self.startRetryCount += 1
                        
                        self.setupScanner { [weak self] success in
                            guard let self = self else { return }
                            if success {
                                print("✅ BarcodeScanner: Setup successful, starting session")
                                self.startRetryCount = 0
                                self.startScanning() // Retry starting now that setup is complete
                            } else {
                                print("❌ BarcodeScanner: Setup failed, retrying...")
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    self.startScanning()
                                }
                            }
                        }
                    } else if authStatus == .notDetermined {
                        // Request authorization
                        self.checkAuthorizationStatus()
                    } else {
                        // Denied or restricted
                        self.isAuthorized = false
                        self.error = .notAuthorized
                        print("❌ BarcodeScanner: Camera access denied or restricted")
                    }
                }
                return
            }
            
            // Session is configured, reset retry count and start
            DispatchQueue.main.async {
                self.startRetryCount = 0
            }
            
            print("🚀 BarcodeScanner: Starting session")
            self.session.startRunning()
            
            DispatchQueue.main.async {
                self.isSessionRunning = self.session.isRunning
                self.isScanning = self.session.isRunning
                self.scannedCode = nil
                self.scannedCodeType = nil
                
                if self.session.isRunning {
                    print("✅ BarcodeScanner: Session started successfully")
                } else {
                    print("❌ BarcodeScanner: Session failed to start")
                    self.error = .unknown
                }
            }
        }
    }
    
    func stopScanning() {
        guard session.isRunning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = false
                self?.isScanning = false
            }
        }
    }
    
    func resetScan() {
        scannedCode = nil
        scannedCodeType = nil
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
                
                // Update metadata output rect of interest if needed
                updateMetadataOutputRect()
            }
        } catch {
            self.error = .inputError(error)
        }
        
        session.commitConfiguration()
    }
    
    private func updateMetadataOutputRect() {
        // Set metadata output rect of interest to full screen
        metadataOutput.rectOfInterest = CGRect(x: 0, y: 0, width: 1, height: 1)
    }
    
    func updateRectOfInterest(_ rect: CGRect) {
        metadataOutput.rectOfInterest = rect
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension BarcodeScannerService: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard isScanning,
              let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let codeString = readableObject.stringValue else {
            return
        }
        
        // Process scanned code
        let codeType = metadataObject.type
        
        DispatchQueue.main.async { [weak self] in
            self?.scannedCode = codeString
            self?.scannedCodeType = codeType
            
            // Call completion handler if set
            self?.onCodeScanned?(codeString, codeType)
            
            // Stop scanning after successful scan
            self?.stopScanning()
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
}

// MARK: - Barcode Scanner Preview Layer

struct BarcodeScannerPreviewView: UIViewRepresentable {
    let scannerService: BarcodeScannerService
    
    func makeUIView(context: Context) -> PreviewContainerView {
        let containerView = PreviewContainerView()
        
        // Create preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: scannerService.session)
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
    
    func updateUIView(_ uiView: PreviewContainerView, context: Context) {
        guard let previewLayer = uiView.previewLayer else { return }
        
        // Update frame when view bounds change
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        previewLayer.frame = uiView.bounds
        CATransaction.commit()
        
        // Update orientation when view updates
        if let connection = previewLayer.connection {
            let statusBarOrientation: UIInterfaceOrientation
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                statusBarOrientation = windowScene.interfaceOrientation
            } else {
                statusBarOrientation = .portrait
            }
            
            if #available(iOS 17.0, *) {
                var rotationAngle: CGFloat = 0.0
                switch statusBarOrientation {
                case .portrait:
                    rotationAngle = 0.0
                case .portraitUpsideDown:
                    rotationAngle = 180.0
                case .landscapeLeft:
                    rotationAngle = 90.0
                case .landscapeRight:
                    rotationAngle = 270.0
                default:
                    rotationAngle = 0.0
                }
                if connection.videoRotationAngle != rotationAngle {
                    connection.videoRotationAngle = rotationAngle
                }
            } else {
                if connection.isVideoOrientationSupported {
                    let targetOrientation: AVCaptureVideoOrientation
                    switch statusBarOrientation {
                    case .portrait:
                        targetOrientation = .portrait
                    case .portraitUpsideDown:
                        targetOrientation = .portraitUpsideDown
                    case .landscapeLeft:
                        targetOrientation = .landscapeLeft
                    case .landscapeRight:
                        targetOrientation = .landscapeRight
                    default:
                        targetOrientation = .portrait
                    }
                    if connection.videoOrientation != targetOrientation {
                        connection.videoOrientation = targetOrientation
                    }
                }
            }
        }
        
        // Update metadata output rect of interest when view layout changes
        if !uiView.bounds.isEmpty, let connection = previewLayer.connection {
            let rect = previewLayer.metadataOutputRectConverted(fromLayerRect: uiView.bounds)
            scannerService.updateRectOfInterest(rect)
        }
    }
}

class PreviewContainerView: UIView {
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
        
        // Update metadata output rect of interest when layout changes
        if let connection = previewLayer.connection {
            let rect = previewLayer.metadataOutputRectConverted(fromLayerRect: bounds)
            if let scannerService = findBarcodeScannerService() {
                scannerService.updateRectOfInterest(rect)
            }
        }
    }
    
    // Helper to find the service - we'll pass it through a different mechanism
    private func findBarcodeScannerService() -> BarcodeScannerService? {
        return BarcodeScannerService.shared
    }
}

// MARK: - Error Types

enum BarcodeScannerError: Error, LocalizedError, Equatable {
    case notAuthorized
    case deviceNotFound
    case inputError(Error)
    case outputError
    case unknown
    
    static func == (lhs: BarcodeScannerError, rhs: BarcodeScannerError) -> Bool {
        switch (lhs, rhs) {
        case (.notAuthorized, .notAuthorized),
             (.deviceNotFound, .deviceNotFound),
             (.outputError, .outputError),
             (.unknown, .unknown):
            return true
        case (.inputError(let lhsError), .inputError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Camera access is required to scan barcodes"
        case .deviceNotFound:
            return "Camera device not found"
        case .inputError(let error):
            return "Camera input error: \(error.localizedDescription)"
        case .outputError:
            return "Metadata output error"
        case .unknown:
            return "Unknown scanner error"
        }
    }
}

// MARK: - Barcode Type Helper

extension AVMetadataObject.ObjectType {
    var displayName: String {
        switch self {
        case .qr:
            return "QR Code"
        case .ean13:
            return "EAN-13"
        case .ean8:
            return "EAN-8"
        case .code128:
            return "Code 128"
        case .code39:
            return "Code 39"
        case .code93:
            return "Code 93"
        case .upce:
            return "UPC-E"
        case .pdf417:
            return "PDF417"
        case .aztec:
            return "Aztec"
        case .dataMatrix:
            return "Data Matrix"
        default:
            return "Barcode"
        }
    }
}

