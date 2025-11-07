//
//  FeatureFlags.swift
//  ReceiptLock
//
//  Created on 08/08/2025.
//
//  Feature flags are read from Info.plist.
//  To configure per build configuration:
//  - Debug/TestFlight: Set RECEIPT_SCAN_ENABLED = YES in project settings
//  - Release/App Store: Set RECEIPT_SCAN_ENABLED = NO in project settings
//

import Foundation

struct FeatureFlags {
    /// Whether receipt scanning is enabled.
    /// Reads from Info.plist key: RECEIPT_SCAN_ENABLED
    /// Defaults to false if the key is missing.
    static var isReceiptScanEnabled: Bool {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "RECEIPT_SCAN_ENABLED") as? Bool else {
            return false
        }
        return value
    }
}

