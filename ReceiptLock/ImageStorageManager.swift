import Foundation
import UIKit
import CoreData

class ImageStorageManager: ObservableObject {
    static let shared = ImageStorageManager()
    
    private let fileManager = FileManager.default
    private let imageQuality: CGFloat = 0.8
    private let maxImageDimension: CGFloat = 2048
    
    private init() {}
    
    // MARK: - Image Storage
    
    func saveReceiptImage(_ image: UIImage, for receipt: Receipt) -> String? {
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let receiptsPath = documentsPath.appendingPathComponent("receipts")
        
        // Create receipts directory if it doesn't exist
        do {
            try fileManager.createDirectory(at: receiptsPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error creating receipts directory: \(error)")
            return nil
        }
        
        // Generate unique filename
        let fileName = "\(receipt.id?.uuidString ?? UUID().uuidString).jpg"
        let fileURL = receiptsPath.appendingPathComponent(fileName)
        
        // Optimize and compress image
        guard let optimizedImage = optimizeImageForStorage(image),
              let imageData = optimizedImage.jpegData(compressionQuality: imageQuality) else {
            return nil
        }
        
        // Save image to file
        do {
            try imageData.write(to: fileURL)
            return fileName
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    func loadReceiptImage(fileName: String) -> UIImage? {
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let imageURL = documentsPath.appendingPathComponent("receipts").appendingPathComponent(fileName)
        
        guard let imageData = try? Data(contentsOf: imageURL) else {
            return nil
        }
        
        return UIImage(data: imageData)
    }
    
    func deleteReceiptImage(fileName: String) {
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let imageURL = documentsPath.appendingPathComponent("receipts").appendingPathComponent(fileName)
        
        do {
            try fileManager.removeItem(at: imageURL)
        } catch {
            print("Error deleting image: \(error)")
        }
    }
    
    // MARK: - Image Optimization
    
    private func optimizeImageForStorage(_ image: UIImage) -> UIImage? {
        let originalSize = image.size
        
        // Check if resizing is needed
        if originalSize.width <= maxImageDimension && originalSize.height <= maxImageDimension {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let aspectRatio = originalSize.width / originalSize.height
        var newSize: CGSize
        
        if originalSize.width > originalSize.height {
            newSize = CGSize(width: maxImageDimension, height: maxImageDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxImageDimension * aspectRatio, height: maxImageDimension)
        }
        
        // Resize image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
    
    // MARK: - Thumbnail Generation
    
    func generateThumbnail(for image: UIImage, size: CGSize = CGSize(width: 200, height: 200)) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return thumbnail
    }
    
    // MARK: - Storage Management
    
    func getStorageUsage() -> (used: Int64, total: Int64) {
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return (0, 0)
        }
        
        let receiptsPath = documentsPath.appendingPathComponent("receipts")
        
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: documentsPath.path)
            let totalSpace = attributes[.systemSize] as? Int64 ?? 0
            
            let receiptFiles = try fileManager.contentsOfDirectory(at: receiptsPath, includingPropertiesForKeys: [.fileSizeKey])
            let usedSpace = receiptFiles.reduce(0) { total, url in
                let fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                return total + Int64(fileSize)
            }
            
            return (usedSpace, totalSpace)
        } catch {
            print("Error calculating storage usage: \(error)")
            return (0, 0)
        }
    }
    
    func cleanupOrphanedImages() {
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let receiptsPath = documentsPath.appendingPathComponent("receipts")
        
        do {
            let imageFiles = try fileManager.contentsOfDirectory(at: receiptsPath, includingPropertiesForKeys: nil)
            
            for imageFile in imageFiles {
                let fileName = imageFile.lastPathComponent
                let receiptId = fileName.replacingOccurrences(of: ".jpg", with: "")
                
                // Check if receipt exists in Core Data
                // This would require a Core Data context to be passed in
                // For now, we'll just log the orphaned files
                print("Potential orphaned image: \(fileName)")
            }
        } catch {
            print("Error cleaning up orphaned images: \(error)")
        }
    }
}
