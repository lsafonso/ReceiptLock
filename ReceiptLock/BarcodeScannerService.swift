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
    
    private func setupScanner() {
        // Prevent multiple setups
        guard session.inputs.isEmpty || session.outputs.isEmpty else {
            return // Already configured
        }
        
        session.beginConfiguration()
        
        // Remove existing inputs/outputs if any
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }
        
        // Set session preset for barcode scanning
        if session.canSetSessionPreset(.high) {
            session.sessionPreset = .high
        } else {
            session.sessionPreset = .medium
        }
        
        // Add video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition) else {
            error = .deviceNotFound
            session.commitConfiguration()
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
                currentCamera = videoDevice
            } else {
                error = .inputError(BarcodeScannerError.deviceNotFound)
                session.commitConfiguration()
                return
            }
        } catch {
            self.error = .inputError(error)
            session.commitConfiguration()
            return
        }
        
        // Add metadata output
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = supportedMetadataTypes
            
            // Configure metadata output connection
            if let connection = metadataOutput.connection(with: .video) {
                if connection.isVideoOrientationSupported {
                    if #available(iOS 17.0, *) {
                        connection.videoRotationAngle = 0.0
                    } else {
                        connection.videoOrientation = .portrait
                    }
                }
            }
        } else {
            error = .outputError
            session.commitConfiguration()
            return
        }
        
        session.commitConfiguration()
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
        
        // Ensure session is configured before starting
        if session.inputs.count == 0 || session.outputs.count == 0 {
            // Session not configured, try to set it up
            if isAuthorized {
                setupScanner()
            } else {
                checkAuthorizationStatus()
            }
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Start session
            self.session.startRunning()
            
            DispatchQueue.main.async {
                self.isSessionRunning = self.session.isRunning
                self.isScanning = self.session.isRunning
                self.scannedCode = nil
                self.scannedCodeType = nil
                
                if !self.session.isRunning {
                    print("Warning: Camera session failed to start")
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
        
        // Configure preview layer connection
        if let connection = previewLayer.connection {
            if connection.isVideoOrientationSupported {
                if #available(iOS 17.0, *) {
                    connection.videoRotationAngle = 0.0
                } else {
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

