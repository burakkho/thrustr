import Foundation
import UIKit
import SwiftData

/**
 * Image management service for file system storage and optimization.
 * 
 * This service handles storing images to file system instead of SwiftData,
 * providing better memory management and performance. Includes compression
 * and thumbnail generation for progress photos and profile pictures.
 * 
 * Features:
 * - File system storage for images
 * - Automatic compression based on image type
 * - Thumbnail generation for quick loading
 * - Thread-safe operations
 * - Cleanup utilities for unused images
 */
@MainActor
class ImageManager {
    static let shared = ImageManager()
    
    private init() {
        createDirectoriesIfNeeded()
    }
    
    // MARK: - Directory Paths
    
    private var documentsDirectory: URL {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Documents directory not available")
        }
        return url
    }
    
    private var imagesDirectory: URL {
        documentsDirectory.appendingPathComponent("Images")
    }
    
    private var profilePicturesDirectory: URL {
        imagesDirectory.appendingPathComponent("ProfilePictures")
    }
    
    private var progressPhotosDirectory: URL {
        imagesDirectory.appendingPathComponent("ProgressPhotos")
    }
    
    private var thumbnailsDirectory: URL {
        imagesDirectory.appendingPathComponent("Thumbnails")
    }
    
    // MARK: - Setup
    
    private func createDirectoriesIfNeeded() {
        let directories = [imagesDirectory, profilePicturesDirectory, progressPhotosDirectory, thumbnailsDirectory]
        
        for directory in directories {
            if !FileManager.default.fileExists(atPath: directory.path) {
                try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            }
        }
    }
    
    // MARK: - Save Images
    
    /**
     * Saves profile picture to file system with compression.
     */
    func saveProfilePicture(_ image: UIImage) -> String? {
        let filename = "profile_\(UUID().uuidString).jpg"
        let url = profilePicturesDirectory.appendingPathComponent(filename)
        
        // Compress to reasonable size for profile picture
        guard let compressedData = compressImage(image, quality: 0.8, maxSize: CGSize(width: 512, height: 512)) else {
            return nil
        }
        
        do {
            try compressedData.write(to: url)
            return url.path
        } catch {
            print("❌ Failed to save profile picture: \(error)")
            return nil
        }
    }
    
    /**
     * Saves progress photo to file system with compression and thumbnail.
     */
    func saveProgressPhoto(_ image: UIImage, type: PhotoType) -> String? {
        let filename = "\(type.rawValue)_\(UUID().uuidString).jpg"
        let url = progressPhotosDirectory.appendingPathComponent(filename)
        
        // Compress progress photo (higher quality than profile picture)
        guard let compressedData = compressImage(image, quality: 0.9, maxSize: CGSize(width: 1024, height: 1024)) else {
            return nil
        }
        
        do {
            try compressedData.write(to: url)
            
            // Create thumbnail for quick loading
            createThumbnail(from: image, filename: filename)
            
            return url.path
        } catch {
            print("❌ Failed to save progress photo: \(error)")
            return nil
        }
    }
    
    // MARK: - Load Images
    
    /**
     * Loads image from file system path.
     */
    func loadImage(from path: String) -> UIImage? {
        guard !path.isEmpty else { return nil }
        return UIImage(contentsOfFile: path)
    }
    
    /**
     * Loads thumbnail for quick display.
     */
    func loadThumbnail(for imagePath: String) -> UIImage? {
        let filename = URL(fileURLWithPath: imagePath).lastPathComponent
        let thumbnailPath = thumbnailsDirectory.appendingPathComponent("thumb_\(filename)")
        return UIImage(contentsOfFile: thumbnailPath.path)
    }
    
    // MARK: - Image Processing
    
    /**
     * Compresses image with specified quality and max size.
     */
    private func compressImage(_ image: UIImage, quality: CGFloat, maxSize: CGSize) -> Data? {
        // Resize if needed
        let resizedImage = resizeImage(image, to: maxSize)
        
        // Compress to JPEG
        return resizedImage.jpegData(compressionQuality: quality)
    }
    
    /**
     * Resizes image maintaining aspect ratio.
     */
    private func resizeImage(_ image: UIImage, to maxSize: CGSize) -> UIImage {
        let size = image.size
        
        // Calculate scaling factor
        let widthRatio = maxSize.width / size.width
        let heightRatio = maxSize.height / size.height
        let scaleFactor = min(widthRatio, heightRatio)
        
        // Don't upscale
        if scaleFactor >= 1.0 {
            return image
        }
        
        let newSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
    
    /**
     * Creates thumbnail for quick loading.
     */
    private func createThumbnail(from image: UIImage, filename: String) {
        let thumbnailSize = CGSize(width: 150, height: 150)
        let thumbnail = resizeImage(image, to: thumbnailSize)
        
        if let thumbnailData = thumbnail.jpegData(compressionQuality: 0.7) {
            let thumbnailURL = thumbnailsDirectory.appendingPathComponent("thumb_\(filename)")
            try? thumbnailData.write(to: thumbnailURL)
        }
    }
    
    // MARK: - Cleanup
    
    /**
     * Deletes image file from file system.
     */
    func deleteImage(at path: String) -> Bool {
        guard !path.isEmpty else { return false }
        
        let url = URL(fileURLWithPath: path)
        let filename = url.lastPathComponent
        
        do {
            // Delete main image
            try FileManager.default.removeItem(at: url)
            
            // Delete thumbnail if exists
            let thumbnailURL = thumbnailsDirectory.appendingPathComponent("thumb_\(filename)")
            try? FileManager.default.removeItem(at: thumbnailURL)
            
            return true
        } catch {
            print("❌ Failed to delete image: \(error)")
            return false
        }
    }
    
    /**
     * Cleanup unused images (call periodically).
     * Removes image files that are no longer referenced in SwiftData.
     */
    func cleanupUnusedImages(modelContext: ModelContext) async {
        Logger.info("🧹 Starting image cleanup process...")

        do {
            // Get all referenced image URLs from SwiftData
            let referencedImagePaths = try await getReferencedImagePaths(modelContext: modelContext)

            // Get all image files from file system
            let allImageFiles = getAllImageFiles()

            // Find unused images
            let unusedImages = allImageFiles.filter { filePath in
                !referencedImagePaths.contains(filePath)
            }

            Logger.info("Found \(unusedImages.count) unused images out of \(allImageFiles.count) total images")

            // Delete unused images
            var deletedCount = 0
            for imagePath in unusedImages {
                if await deleteImageFile(at: imagePath) {
                    deletedCount += 1
                }
            }

            Logger.success("✅ Image cleanup completed: deleted \(deletedCount) unused images")

        } catch {
            Logger.error("❌ Image cleanup failed: \(error)")
        }
    }

    // MARK: - Private Cleanup Helpers

    private func getReferencedImagePaths(modelContext: ModelContext) async throws -> Set<String> {
        var referencedPaths = Set<String>()

        // Get all user profile picture URLs
        let userDescriptor = FetchDescriptor<User>()
        let users = try modelContext.fetch(userDescriptor)

        for user in users {
            if let profileURL = user.profilePictureURL, !profileURL.isEmpty {
                referencedPaths.insert(profileURL)
            }
        }

        // Get all progress photo URLs
        let photoDescriptor = FetchDescriptor<ProgressPhoto>()
        let progressPhotos = try modelContext.fetch(photoDescriptor)

        for photo in progressPhotos {
            if let imageURL = photo.imageURL, !imageURL.isEmpty {
                referencedPaths.insert(imageURL)
            }
        }

        Logger.info("Found \(referencedPaths.count) referenced image paths in database")
        return referencedPaths
    }

    private func getAllImageFiles() -> [String] {
        var allFiles: [String] = []

        let directories = [profilePicturesDirectory, progressPhotosDirectory, thumbnailsDirectory]

        for directory in directories {
            do {
                let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
                let imagePaths = files.map { $0.path }
                allFiles.append(contentsOf: imagePaths)
            } catch {
                Logger.warning("Could not read directory \(directory.path): \(error)")
            }
        }

        return allFiles
    }

    private func deleteImageFile(at path: String) async -> Bool {
        do {
            try FileManager.default.removeItem(atPath: path)
            Logger.info("Deleted unused image: \(URL(fileURLWithPath: path).lastPathComponent)")
            return true
        } catch {
            Logger.error("Failed to delete image at \(path): \(error)")
            return false
        }
    }
}

// Note: PhotoType enum is defined in BodyTrackingModels.swift