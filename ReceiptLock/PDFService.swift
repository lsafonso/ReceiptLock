//
//  PDFService.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//
//  This service handles PDF processing and OCR extraction from PDF documents.
//  It provides functionality to:
//  - Extract text directly from PDF documents
//  - Convert PDF pages to images for OCR processing
//  - Combine direct text extraction with OCR results
//  - Validate PDF files and extract metadata
//  - Track processing progress for better user experience
//

import Foundation
import PDFKit
import Vision
import UIKit

// MARK: - PDF Processing Result
struct PDFProcessingResult {
    let success: Bool
    let extractedText: String
    let pageCount: Int
    let error: Error?
    let extractedImages: [UIImage]
}

// MARK: - PDF Service
class PDFService: ObservableObject {
    static let shared = PDFService()
    
    @Published var processingProgress: Double = 0.0
    @Published var isProcessing = false
    
    private init() {}
    
    // MARK: - PDF Text Extraction
    
    /// Extract text from PDF document
    func extractTextFromPDF(at url: URL) async throws -> String {
        guard let pdfDocument = PDFDocument(url: url) else {
            throw PDFProcessingError.invalidPDFDocument
        }
        
        // Check file size (limit to 50MB)
        let fileSize = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        if fileSize > 50 * 1024 * 1024 { // 50MB
            throw PDFProcessingError.fileTooLarge
        }
        
        var extractedText = ""
        
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }
            
            if let pageText = page.string {
                extractedText += pageText + "\n"
            }
        }
        
        if extractedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw PDFProcessingError.noTextFound
        }
        
        return extractedText
    }
    
    /// Extract images from PDF document
    func extractImagesFromPDF(at url: URL) async throws -> [UIImage] {
        guard let pdfDocument = PDFDocument(url: url) else {
            throw PDFProcessingError.invalidPDFDocument
        }
        
        var extractedImages: [UIImage] = []
        
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }
            
            let pageImages = extractImagesFromPage(page)
            extractedImages.append(contentsOf: pageImages)
        }
        
        return extractedImages
    }
    
    /// Process PDF with OCR for better text extraction
    func processPDFWithOCR(at url: URL) async throws -> PDFProcessingResult {
        await MainActor.run {
            isProcessing = true
            processingProgress = 0.0
        }
        
        // First try to extract text directly (20% progress)
        let directText = try await extractTextFromPDF(at: url)
        await MainActor.run {
            processingProgress = 0.2
        }
        
        // Extract images for OCR processing (40% progress)
        let images = try await extractImagesFromPDF(at: url)
        await MainActor.run {
            processingProgress = 0.4
        }
        
        var ocrText = ""
        let totalImages = images.count
        
        // Process each image with OCR (40% to 90% progress)
        for (index, image) in images.enumerated() {
            do {
                let imageText = try await OCRService.shared.processReceiptImage(image)
                ocrText += imageText.rawText + "\n"
                
                await MainActor.run {
                    processingProgress = 0.4 + (0.5 * Double(index + 1) / Double(totalImages))
                }
            } catch {
                print("OCR processing failed for image: \(error.localizedDescription)")
                // Continue with other images
            }
        }
        
        // Combine direct text extraction with OCR results
        let combinedText = directText + "\n" + ocrText
        
        guard let pdfDocument = PDFDocument(url: url) else {
            throw PDFProcessingError.invalidPDFDocument
        }
        
        // If no text was extracted, try to process the first image with OCR
        if combinedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !images.isEmpty {
            do {
                let imageText = try await OCRService.shared.processReceiptImage(images[0])
                ocrText = imageText.rawText
            } catch {
                print("OCR processing failed for PDF image: \(error.localizedDescription)")
            }
        }
        
        await MainActor.run {
            processingProgress = 1.0
            isProcessing = false
        }
        
        return PDFProcessingResult(
            success: true,
            extractedText: combinedText.isEmpty ? ocrText : combinedText,
            pageCount: pdfDocument.pageCount,
            error: nil,
            extractedImages: images
        )
    }
    
    /// Convert PDF to images for OCR processing
    func convertPDFToImages(at url: URL, maxPages: Int = 10) async throws -> [UIImage] {
        guard let pdfDocument = PDFDocument(url: url) else {
            throw PDFProcessingError.invalidPDFDocument
        }
        
        var images: [UIImage] = []
        let pageCount = min(pdfDocument.pageCount, maxPages)
        
        for pageIndex in 0..<pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }
            
            let pageRect = page.bounds(for: .mediaBox)
            let renderer = UIGraphicsImageRenderer(size: pageRect.size)
            
            let image = renderer.image { context in
                UIColor.white.setFill()
                context.fill(pageRect)
                
                context.cgContext.translateBy(x: 0, y: pageRect.size.height)
                context.cgContext.scaleBy(x: 1.0, y: -1.0)
                
                page.draw(with: .mediaBox, to: context.cgContext)
            }
            
            images.append(image)
        }
        
        return images
    }
    
    // MARK: - Helper Methods
    
    private func extractImagesFromPage(_ page: PDFPage) -> [UIImage] {
        var images: [UIImage] = []
        
        // Get page bounds
        let pageRect = page.bounds(for: .mediaBox)
        
        // Create a high-resolution image of the page
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        let pageImage = renderer.image { context in
            UIColor.white.setFill()
            context.fill(pageRect)
            
            context.cgContext.translateBy(x: 0, y: pageRect.size.height)
            context.cgContext.scaleBy(x: 1.0, y: -1.0)
            
            page.draw(with: .mediaBox, to: context.cgContext)
        }
        
        images.append(pageImage)
        
        return images
    }
    
    /// Validate PDF file
    func validatePDF(at url: URL) -> Bool {
        guard let pdfDocument = PDFDocument(url: url) else { return false }
        
        // Check if PDF has content
        if pdfDocument.pageCount == 0 { return false }
        
        // Check if PDF is corrupted
        guard let firstPage = pdfDocument.page(at: 0) else { return false }
        let pageRect = firstPage.bounds(for: .mediaBox)
        if pageRect.width <= 0 || pageRect.height <= 0 { return false }
        
        return true
    }
    
    /// Get PDF metadata
    func getPDFMetadata(at url: URL) -> PDFMetadata? {
        guard let pdfDocument = PDFDocument(url: url) else { return nil }
        
        let attributes = pdfDocument.documentAttributes
        let pageCount = pdfDocument.pageCount
        
        return PDFMetadata(
            pageCount: pageCount,
            title: attributes?[PDFDocumentAttribute.titleAttribute] as? String,
            author: attributes?[PDFDocumentAttribute.authorAttribute] as? String,
            subject: attributes?[PDFDocumentAttribute.subjectAttribute] as? String,
            creator: attributes?[PDFDocumentAttribute.creatorAttribute] as? String,
            creationDate: attributes?[PDFDocumentAttribute.creationDateAttribute] as? Date,
            modificationDate: attributes?[PDFDocumentAttribute.modificationDateAttribute] as? Date
        )
    }
}

// MARK: - PDF Metadata
struct PDFMetadata {
    let pageCount: Int
    let title: String?
    let author: String?
    let subject: String?
    let creator: String?
    let creationDate: Date?
    let modificationDate: Date?
}

// MARK: - PDF Processing Errors
enum PDFProcessingError: LocalizedError {
    case invalidPDFDocument
    case noTextFound
    case processingFailed
    case unsupportedFormat
    case fileTooLarge
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .invalidPDFDocument:
            return "Invalid or corrupted PDF document"
        case .noTextFound:
            return "No text content found in PDF"
        case .processingFailed:
            return "Failed to process PDF document"
        case .unsupportedFormat:
            return "Unsupported PDF format"
        case .fileTooLarge:
            return "PDF file is too large to process"
        case .permissionDenied:
            return "Permission denied to access PDF file"
        }
    }
}

// MARK: - PDF Preview Helper
struct PDFPreviewView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        if let document = PDFDocument(url: url) {
            pdfView.document = document
        }
    }
}
