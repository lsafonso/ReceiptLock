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
            "from:", "purchased at:", "bought at:"
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
               !cleanLine.contains("tax") {
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
            DateFormatter(format: "MMMM dd, yyyy")
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
            #"(\w+)\s+(\d{1,2}),?\s+(\d{4})"#
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
            "model:", "brand:", "type:", "category:"
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
               !cleanLine.contains("cash") {
                return cleanLine
            }
        }
        
        return nil
    }
    
    private func extractWarrantyInfo(from text: String) -> String? {
        let warrantyKeywords = [
            "warranty", "guarantee", "coverage", "protection", "assurance",
            "guaranty", "warrant", "coverage period", "warranty period",
            "limited warranty", "extended warranty", "manufacturer warranty"
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
            #"local[\s]*tax[\s:]*\$?(\d+\.?\d*)"#
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
            #"total[\s]*amount[\s:]*\$?(\d+\.?\d*)"#
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
            "venmo", "zelle", "bitcoin", "crypto"
        ]
        
        for method in paymentMethods {
            if text.range(of: method, options: .caseInsensitive) != nil {
                return method.capitalized
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
