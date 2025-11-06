//
//  CodeScannerView.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI
import VisionKit
import AVFoundation

struct CodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isScanning = false
    @State private var showingFallback = false
    @State private var dataScannerAvailable = false
    
    let onScanned: (String) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            if dataScannerAvailable && !showingFallback {
                // VisionKit DataScannerViewController
                DataScannerViewControllerRepresentable(
                    isScanning: $isScanning,
                    onScanned: { code in
                        onScanned(code)
                        dismiss()
                    }
                )
            } else if showingFallback {
                // AVFoundation fallback
                AVFoundationBarcodeScannerView(
                    onScanned: { code in
                        onScanned(code)
                        dismiss()
                    },
                    onCancel: {
                        onCancel()
                        dismiss()
                    }
                )
            } else {
                // Checking availability
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Text("Initializing scanner...")
                        .foregroundColor(.white)
                        .padding(.top)
                }
            }
        }
        .onAppear {
            checkDataScannerAvailability()
        }
        .onDisappear {
            isScanning = false
        }
    }
    
    private func checkDataScannerAvailability() {
        // Check if DataScannerViewController is available (iOS 16+)
        if #available(iOS 16.0, *) {
            // Check if device supports data scanning
            let supported = DataScannerViewController.isSupported
            let available = DataScannerViewController.isAvailable
            
            if supported && available {
                dataScannerAvailable = true
                isScanning = true
            } else {
                // Fallback to AVFoundation
                showingFallback = true
            }
        } else {
            // iOS < 16, use AVFoundation
            showingFallback = true
        }
    }
}

// MARK: - VisionKit DataScannerViewController Wrapper

@available(iOS 16.0, *)
struct DataScannerViewControllerRepresentable: UIViewControllerRepresentable {
    @Binding var isScanning: Bool
    let onScanned: (String) -> Void
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [
                .barcode(symbologies: [.qr, .ean13, .code128, .code39, .upce])
            ],
            qualityLevel: .accurate,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: true
        )
        
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if isScanning {
            do {
                try uiViewController.startScanning()
            } catch {
                print("❌ [CodeScanner] Failed to start scanning: \(error.localizedDescription)")
            }
        } else {
            uiViewController.stopScanning()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onScanned: onScanned)
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onScanned: (String) -> Void
        private var lastScannedValue: String?
        private var lastScanAt = Date.distantPast
        
        init(onScanned: @escaping (String) -> Void) {
            self.onScanned = onScanned
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            handleRecognizedItem(item)
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            // Automatically scan when barcode is detected (first one found)
            for item in addedItems {
                if case .barcode(let barcode) = item {
                    if let payload = barcode.payloadStringValue {
                        handleRecognizedItem(item)
                        break // Only process the first detected barcode
                    }
                }
            }
        }
        
        private func handleRecognizedItem(_ item: RecognizedItem) {
            switch item {
            case .barcode(let barcode):
                if let payload = barcode.payloadStringValue {
                    // Debounce: ignore if same value and within 1 second
                    let now = Date()
                    if payload == lastScannedValue && now.timeIntervalSince(lastScanAt) < 1.0 {
                        return
                    }
                    
                    // Accept this scan
                    lastScannedValue = payload
                    lastScanAt = now
                    
                    // Light haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    onScanned(payload)
                }
            default:
                break
            }
        }
    }
}

// MARK: - AVFoundation Fallback Scanner

struct AVFoundationBarcodeScannerView: View {
    @StateObject private var scannerService = BarcodeScannerService.shared
    @Environment(\.dismiss) private var dismiss
    
    let onScanned: (String) -> Void
    let onCancel: () -> Void
    
    @State private var lastScannedValue: String?
    @State private var lastScanAt = Date.distantPast
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            if scannerService.isAuthorized && scannerService.isSessionRunning {
                BarcodeScannerPreviewView(scannerService: scannerService)
                    .ignoresSafeArea()
                
                // Overlay with instructions
                VStack {
                    Spacer()
                    VStack(spacing: 12) {
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
                    .padding(.bottom, 50)
                }
            } else if scannerService.isAuthorized {
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Text("Starting camera...")
                        .foregroundColor(.white)
                        .padding(.top)
                }
            } else {
                CameraPermissionView()
            }
            
            // Top controls
            VStack {
                HStack {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(.black.opacity(0.6))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
                
                Spacer()
            }
        }
        .onAppear {
            scannerService.onCodeScanned = { code, type in
                // Debounce: ignore if same value and within 1 second
                let now = Date()
                if code == lastScannedValue && now.timeIntervalSince(lastScanAt) < 1.0 {
                    return
                }
                
                // Accept this scan
                lastScannedValue = code
                lastScanAt = now
                
                // Light haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                
                onScanned(code)
            }
            
            if scannerService.isAuthorized {
                scannerService.startScanning()
            }
        }
        .onDisappear {
            scannerService.stopScanning()
            scannerService.resetScan()
        }
    }
}

// MARK: - Camera Permission View
// Note: CameraPermissionView is defined in CameraView.swift

#Preview {
    CodeScannerView(
        onScanned: { code in
            print("Scanned: \(code)")
        },
        onCancel: {
            print("Cancelled")
        }
    )
}

