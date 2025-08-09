import Foundation
import Vision
import VisionKit
import UIKit

class OCRService: ObservableObject {
    static let shared = OCRService()
    
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    
    private init() {}
    
    // MARK: - OCR Processing
    
    func processReceiptImage(_ image: UIImage) async throws -> ReceiptData {
        await MainActor.run {
            isProcessing = true
            processingProgress = 0.0
        }
        
        defer {
            Task { @MainActor in
                isProcessing = false
                processingProgress = 0.0
            }
        }
        
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        await MainActor.run {
            processingProgress = 0.2
        }
        
        let text = try await performOCR(on: cgImage)
        
        await MainActor.run {
            processingProgress = 0.6
        }
        
        let extractedData = extractReceiptData(from: text)
        
        await MainActor.run {
            processingProgress = 1.0
        }
        
        return extractedData
    }
    
    private func performOCR(on cgImage: CGImage) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.processingFailed(error))
                    return
                }
                
                guard let observations = request.results else {
                    continuation.resume(throwing: OCRError.noResults)
                    return
                }
                
                let recognizedText = observations.compactMap { observation in
                    (observation as? VNRecognizedTextObservation)?.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                continuation.resume(returning: recognizedText)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US"]
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.processingFailed(error))
            }
        }
    }
    
    // MARK: - Smart Data Extraction
    
    private func extractReceiptData(from text: String) -> ReceiptData {
        var extractedData = ReceiptData()
        extractedData.rawText = text
        
        // Extract price with improved patterns
        extractedData.price = extractPrice(from: text)
        
        // Extract store name with better detection
        extractedData.store = extractStoreName(from: text)
        
        // Extract date with multiple format support
        extractedData.purchaseDate = extractDate(from: text)
        
        // Extract title/description with context
        extractedData.title = extractTitle(from: text)
        
        // Extract warranty information
        extractedData.warrantyInfo = extractWarrantyInfo(from: text)
        
        // Extract additional fields
        extractedData.taxAmount = extractTaxAmount(from: text)
        extractedData.totalAmount = extractTotalAmount(from: text)
        extractedData.paymentMethod = extractPaymentMethod(from: text)
        extractedData.receiptNumber = extractReceiptNumber(from: text)
        extractedData.cashierInfo = extractCashierInfo(from: text)
        extractedData.storeAddress = extractStoreAddress(from: text)
        extractedData.storePhone = extractStorePhone(from: text)
        extractedData.storeWebsite = extractStoreWebsite(from: text)
        
        return extractedData
    }
    
    private func extractPrice(from text: String) -> Double? {
        // Enhanced price patterns for receipts
        let pricePatterns = [
            #"total[\s:]*\$?(\d+\.?\d*)"#,
            #"amount[\s:]*\$?(\d+\.?\d*)"#,
            #"subtotal[\s:]*\$?(\d+\.?\d*)"#,
            #"grand[\s]*total[\s:]*\$?(\d+\.?\d*)"#,
            #"balance[\s:]*\$?(\d+\.?\d*)"#,
            #"due[\s:]*\$?(\d+\.?\d*)"#,
            #"final[\s]*total[\s:]*\$?(\d+\.?\d*)"#,
            #"amount[\s]*due[\s:]*\$?(\d+\.?\d*)"#,
            #"final[\s]*amount[\s:]*\$?(\d+\.?\d*)"#,
            #"balance[\s]*due[\s:]*\$?(\d+\.?\d*)"#,
            #"total[\s]*amount[\s:]*\$?(\d+\.?\d*)"#,
            #"final[\s]*balance[\s:]*\$?(\d+\.?\d*)"#,
            #"\$(\d+\.?\d*)"#,
            #"(\d+\.?\d*)[\s]*\$"#,
            #"(\d+\.?\d*)"#
        ]
        
        for pattern in pricePatterns {
            if let match = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let matchedText = String(text[match])
                let cleanText = matchedText
                    .replacingOccurrences(of: "$", with: "")
                    .replacingOccurrences(of: "total", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "amount", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "subtotal", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "grand", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "balance", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "due", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "final", with: "", options: .caseInsensitive)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if let priceValue = Double(cleanText) {
                    return priceValue
                }
            }
        }
        
        return nil
    }
    
    private func extractStoreName(from text: String) -> String? {
        // Enhanced store name detection
        let storeIndicators = [
            "store:", "shop:", "retailer:", "merchant:", "vendor:",
            "company:", "business:", "outlet:", "market:", "location:",
            "branch:", "franchise:", "chain:", "establishment:",
            "from:", "purchased at:", "bought at:", "retailer:",
            "merchant:", "vendor:", "dealer:", "distributor:"
        ]
        
        for indicator in storeIndicators {
            if let range = text.range(of: indicator, options: .caseInsensitive) {
                let startIndex = text.index(range.upperBound, offsetBy: 0)
                let endIndex = text.index(startIndex, offsetBy: 50, limitedBy: text.endIndex) ?? text.endIndex
                let storeName = String(text[startIndex..<endIndex])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .components(separatedBy: .newlines).first ?? ""
                
                if !storeName.isEmpty && storeName.count > 2 {
                    return storeName
                }
            }
        }
        
        // Fallback: look for common store names in the first few lines
        let lines = text.components(separatedBy: .newlines)
        let firstLines = Array(lines.prefix(8))
        
        for line in firstLines {
            let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleanLine.count > 3 && cleanLine.count < 50 && 
               !cleanLine.contains("$") && 
               !cleanLine.contains("total") &&
               !cleanLine.contains("date") &&
               !cleanLine.contains("time") &&
               !cleanLine.contains("receipt") &&
               !cleanLine.contains("subtotal") &&
               !cleanLine.contains("tax") &&
               !cleanLine.contains("cashier") &&
               !cleanLine.contains("register") {
                return cleanLine
            }
        }
        
        return nil
    }
    
    private func extractDate(from text: String) -> Date? {
        let dateFormatters = [
            DateFormatter(format: "MM/dd/yyyy"),
            DateFormatter(format: "MM-dd-yyyy"),
            DateFormatter(format: "MM.dd.yyyy"),
            DateFormatter(format: "MM/dd/yy"),
            DateFormatter(format: "MM-dd-yy"),
            DateFormatter(format: "MM.dd.yy"),
            DateFormatter(format: "dd/MM/yyyy"),
            DateFormatter(format: "dd-MM-yyyy"),
            DateFormatter(format: "dd.MM.yyyy"),
            DateFormatter(format: "yyyy-MM-dd"),
            DateFormatter(format: "MMM dd, yyyy"),
            DateFormatter(format: "MMMM dd, yyyy"),
            DateFormatter(format: "MMM dd yyyy"),
            DateFormatter(format: "MMMM dd yyyy")
        ]
        
        // Enhanced date patterns for receipts
        let datePatterns = [
            #"(\d{1,2})/(\d{1,2})/(\d{4})"#,
            #"(\d{1,2})-(\d{1,2})-(\d{4})"#,
            #"(\d{1,2})\.(\d{1,2})\.(\d{4})"#,
            #"(\d{1,2})/(\d{1,2})/(\d{2})"#,
            #"(\d{1,2})-(\d{1,2})-(\d{2})"#,
            #"(\d{1,2})\.(\d{1,2})\.(\d{2})"#,
            #"(\d{4})-(\d{1,2})-(\d{1,2})"#,
            #"(\w{3})\s+(\d{1,2}),?\s+(\d{4})"#,
            #"(\w+)\s+(\d{1,2}),?\s+(\d{4})"#,
            #"(\w{3})\s+(\d{1,2})\s+(\d{4})"#,
            #"(\w+)\s+(\d{1,2})\s+(\d{4})"#
        ]
        
        for pattern in datePatterns {
            if let match = text.range(of: pattern, options: .regularExpression) {
                let dateString = String(text[match])
                
                for formatter in dateFormatters {
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                }
            }
        }
        
        // Try to find today's date if no date found
        return Date()
    }
    
    private func extractTitle(from text: String) -> String? {
        // Enhanced product/description detection
        let productIndicators = [
            "item:", "product:", "description:", "name:", "goods:",
            "merchandise:", "article:", "commodity:", "purchase:",
            "model:", "brand:", "type:", "category:", "service:",
            "work:", "labor:", "installation:", "delivery:"
        ]
        
        for indicator in productIndicators {
            if let range = text.range(of: indicator, options: .caseInsensitive) {
                let startIndex = text.index(range.upperBound, offsetBy: 0)
                let endIndex = text.index(startIndex, offsetBy: 100, limitedBy: text.endIndex) ?? text.endIndex
                let title = String(text[startIndex..<endIndex])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .components(separatedBy: .newlines).first ?? ""
                
                if !title.isEmpty && title.count > 3 {
                    return title
                }
            }
        }
        
        // Look for product descriptions in the middle section of the receipt
        let lines = text.components(separatedBy: .newlines)
        let middleStart = max(0, lines.count / 3)
        let middleEnd = min(lines.count, 2 * lines.count / 3)
        let middleLines = Array(lines[middleStart..<middleEnd])
        
        for line in middleLines {
            let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleanLine.count > 5 && cleanLine.count < 80 && 
               !cleanLine.contains("$") && 
               !cleanLine.contains("total") &&
               !cleanLine.contains("date") &&
               !cleanLine.contains("time") &&
               !cleanLine.contains("receipt") &&
               !cleanLine.contains("subtotal") &&
               !cleanLine.contains("tax") &&
               !cleanLine.contains("change") &&
               !cleanLine.contains("cash") &&
               !cleanLine.contains("cashier") &&
               !cleanLine.contains("register") {
                return cleanLine
            }
        }
        
        return nil
    }
    
    private func extractWarrantyInfo(from text: String) -> String? {
        let warrantyKeywords = [
            "warranty", "guarantee", "coverage", "protection", "assurance",
            "guaranty", "warrant", "coverage period", "warranty period",
            "limited warranty", "extended warranty", "manufacturer warranty",
            "return policy", "exchange policy", "refund policy"
        ]
        
        for keyword in warrantyKeywords {
            if let range = text.range(of: keyword, options: .caseInsensitive) {
                let startIndex = text.index(range.lowerBound, offsetBy: -30, limitedBy: text.startIndex) ?? text.startIndex
                let endIndex = text.index(range.upperBound, offsetBy: 80, limitedBy: text.endIndex) ?? text.endIndex
                let warrantyText = String(text[startIndex..<endIndex])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !warrantyText.isEmpty {
                    return warrantyText
                }
            }
        }
        
        return nil
    }
    
    private func extractTaxAmount(from text: String) -> Double? {
        let taxPatterns = [
            #"tax[\s:]*\$?(\d+\.?\d*)"#,
            #"sales[\s]*tax[\s:]*\$?(\d+\.?\d*)"#,
            #"vat[\s:]*\$?(\d+\.?\d*)"#,
            #"gst[\s:]*\$?(\d+\.?\d*)"#,
            #"state[\s]*tax[\s:]*\$?(\d+\.?\d*)"#,
            #"local[\s]*tax[\s:]*\$?(\d+\.?\d*)"#,
            #"provincial[\s]*tax[\s:]*\$?(\d+\.?\d*)"#,
            #"federal[\s]*tax[\s:]*\$?(\d+\.?\d*)"#
        ]
        
        for pattern in taxPatterns {
            if let match = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let matchedText = String(text[match])
                let cleanText = matchedText
                    .replacingOccurrences(of: "$", with: "")
                    .replacingOccurrences(of: "tax", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "sales", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "vat", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "gst", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "state", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "local", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "provincial", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "federal", with: "", options: .caseInsensitive)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if let taxValue = Double(cleanText) {
                    return taxValue
                }
            }
        }
        
        return nil
    }
    
    private func extractTotalAmount(from text: String) -> Double? {
        let totalPatterns = [
            #"total[\s:]*\$?(\d+\.?\d*)"#,
            #"grand[\s]*total[\s:]*\$?(\d+\.?\d*)"#,
            #"final[\s]*total[\s:]*\$?(\d+\.?\d*)"#,
            #"amount[\s]*due[\s:]*\$?(\d+\.?\d*)"#,
            #"balance[\s]*due[\s:]*\$?(\d+\.?\d*)"#,
            #"total[\s]*amount[\s:]*\$?(\d+\.?\d*)"#,
            #"final[\s]*amount[\s:]*\$?(\d+\.?\d*)"#,
            #"final[\s]*balance[\s:]*\$?(\d+\.?\d*)"#
        ]
        
        for pattern in totalPatterns {
            if let match = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let matchedText = String(text[match])
                let cleanText = matchedText
                    .replacingOccurrences(of: "$", with: "")
                    .replacingOccurrences(of: "total", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "grand", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "final", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "amount", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "due", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "balance", with: "", options: .caseInsensitive)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if let totalValue = Double(cleanText) {
                    return totalValue
                }
            }
        }
        
        return nil
    }
    
    private func extractPaymentMethod(from text: String) -> String? {
        let paymentMethods = [
            "cash", "credit card", "debit card", "visa", "mastercard",
            "amex", "american express", "paypal", "apple pay", "google pay",
            "check", "money order", "gift card", "store credit", "bank transfer",
            "venmo", "zelle", "bitcoin", "crypto", "contactless",
            "chip card", "swipe card", "tap to pay"
        ]
        
        for method in paymentMethods {
            if text.range(of: method, options: .caseInsensitive) != nil {
                return method.capitalized
            }
        }
        
        return nil
    }
    
    private func extractReceiptNumber(from text: String) -> String? {
        let receiptPatterns = [
            #"receipt[\s]*#?[\s:]*(\w+)"#,
            #"receipt[\s]*number[\s:]*(\w+)"#,
            #"transaction[\s]*#?[\s:]*(\w+)"#,
            #"transaction[\s]*id[\s:]*(\w+)"#,
            #"order[\s]*#?[\s:]*(\w+)"#,
            #"order[\s]*number[\s:]*(\w+)"#,
            #"invoice[\s]*#?[\s:]*(\w+)"#,
            #"invoice[\s]*number[\s:]*(\w+)"#
        ]
        
        for pattern in receiptPatterns {
            if let match = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let matchedText = String(text[match])
                let cleanText = matchedText
                    .replacingOccurrences(of: "receipt", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "transaction", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "order", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "invoice", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "number", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "#", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: ":", with: "", options: .caseInsensitive)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !cleanText.isEmpty {
                    return cleanText
                }
            }
        }
        
        return nil
    }
    
    private func extractCashierInfo(from text: String) -> String? {
        let cashierPatterns = [
            #"cashier[\s:]*(\w+)"#,
            #"clerk[\s:]*(\w+)"#,
            #"associate[\s:]*(\w+)"#,
            #"employee[\s:]*(\w+)"#,
            #"staff[\s:]*(\w+)"#,
            #"register[\s:]*(\w+)"#
        ]
        
        for pattern in cashierPatterns {
            if let match = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let matchedText = String(text[match])
                let cleanText = matchedText
                    .replacingOccurrences(of: "cashier", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "clerk", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "associate", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "employee", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "staff", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "register", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: ":", with: "", options: .caseInsensitive)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !cleanText.isEmpty {
                    return cleanText
                }
            }
        }
        
        return nil
    }
    
    private func extractStoreAddress(from text: String) -> String? {
        let addressPatterns = [
            #"address[\s:]*([^\n]+)"#,
            #"location[\s:]*([^\n]+)"#,
            #"street[\s:]*([^\n]+)"#,
            #"(\d+\s+[A-Za-z\s]+(?:Street|St|Avenue|Ave|Road|Rd|Boulevard|Blvd|Drive|Dr|Lane|Ln|Way|Court|Ct|Place|Pl))"#
        ]
        
        for pattern in addressPatterns {
            if let match = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let matchedText = String(text[match])
                let cleanText = matchedText
                    .replacingOccurrences(of: "address", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "location", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "street", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: ":", with: "", options: .caseInsensitive)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !cleanText.isEmpty && cleanText.count > 10 {
                    return cleanText
                }
            }
        }
        
        return nil
    }
    
    private func extractStorePhone(from text: String) -> String? {
        let phonePatterns = [
            #"phone[\s:]*([\d\-\(\)\s]+)"#,
            #"tel[\s:]*([\d\-\(\)\s]+)"#,
            #"call[\s:]*([\d\-\(\)\s]+)"#,
            #"(\(\d{3}\)\s*\d{3}-\d{4})"#,
            #"(\d{3}-\d{3}-\d{4})"#,
            #"(\d{3}\.\d{3}\.\d{4})"#
        ]
        
        for pattern in phonePatterns {
            if let match = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let matchedText = String(text[match])
                let cleanText = matchedText
                    .replacingOccurrences(of: "phone", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "tel", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "call", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: ":", with: "", options: .caseInsensitive)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !cleanText.isEmpty && cleanText.count >= 10 {
                    return cleanText
                }
            }
        }
        
        return nil
    }
    
    private func extractStoreWebsite(from text: String) -> String? {
        let websitePatterns = [
            #"website[\s:]*([^\s\n]+)"#,
            #"web[\s:]*([^\s\n]+)"#,
            #"site[\s:]*([^\s\n]+)"#,
            #"(https?://[^\s\n]+)"#,
            #"(www\.[^\s\n]+)"#
        ]
        
        for pattern in websitePatterns {
            if let match = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let matchedText = String(text[match])
                let cleanText = matchedText
                    .replacingOccurrences(of: "website", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "web", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "site", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: ":", with: "", options: .caseInsensitive)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !cleanText.isEmpty && (cleanText.hasPrefix("http") || cleanText.hasPrefix("www")) {
                    return cleanText
                }
            }
        }
        
        return nil
    }
}

// MARK: - Data Structures

struct ReceiptData {
    var title: String?
    var store: String?
    var price: Double?
    var purchaseDate: Date?
    var warrantyInfo: String?
    var taxAmount: Double?
    var totalAmount: Double?
    var paymentMethod: String?
    var receiptNumber: String?
    var cashierInfo: String?
    var storeAddress: String?
    var storePhone: String?
    var storeWebsite: String?
    var rawText: String = ""
}

// MARK: - Error Types

enum OCRError: Error, LocalizedError {
    case invalidImage
    case noResults
    case processingFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .noResults:
            return "No text could be extracted from the image"
        case .processingFailed(let error):
            return "OCR processing failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - DateFormatter Extension

extension DateFormatter {
    convenience init(format: String) {
        self.init()
        self.dateFormat = format
    }
}
