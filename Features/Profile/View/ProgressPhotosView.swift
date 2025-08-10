import SwiftUI
import SwiftData
import PhotosUI

struct ProgressPhotosView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedPhotoType: PhotoType = .front
    @State private var showingAddPhotoSheet = false
    @State private var showingDeleteAlert = false
    @State private var photoToDelete: ProgressPhoto?
    
    @Query(
        sort: \ProgressPhoto.date,
        order: .reverse
    ) private var progressPhotos: [ProgressPhoto]
    
    var groupedPhotos: [String: [ProgressPhoto]] {
        Dictionary(grouping: progressPhotos) { photo in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: photo.date)
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if progressPhotos.isEmpty {
                    EmptyProgressPhotosView(onAddPhoto: { showingAddPhotoSheet = true })
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Photo Types Overview
                            PhotoTypesOverviewSection(photos: progressPhotos)
                            
                            // Timeline View
                            PhotoTimelineSection(
                                groupedPhotos: groupedPhotos,
                                onDeletePhoto: { photo in
                                    photoToDelete = photo
                                    showingDeleteAlert = true
                                }
                            )
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("progress_photos.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.close".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddPhotoSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
        }
        .sheet(isPresented: $showingAddPhotoSheet) {
            AddProgressPhotoView(
                selectedPhotoType: $selectedPhotoType,
                onPhotoAdded: {
                    showingAddPhotoSheet = false
                }
            )
        }
        .alert("progress_photos.delete_photo".localized, isPresented: $showingDeleteAlert) {
            Button("common.delete".localized, role: .destructive) {
                if let photo = photoToDelete {
                    deletePhoto(photo)
                }
            }
            Button("common.cancel".localized, role: .cancel) { }
        } message: {
            Text("progress_photos.delete_message".localized)
        }
    }
    
    private func deletePhoto(_ photo: ProgressPhoto) {
        modelContext.delete(photo)
        
        do {
            try modelContext.save()
        } catch {
            print("Error deleting photo: \(error)")
        }
    }
}

// MARK: - Empty State View
struct EmptyProgressPhotosView: View {
    let onAddPhoto: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "camera.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("progress_photos.title".localized)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("progress_photos.subtitle".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button {
                onAddPhoto()
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("progress_photos.add_first".localized)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

// MARK: - Photo Types Overview Section
struct PhotoTypesOverviewSection: View {
    let photos: [ProgressPhoto]
    
    private func latestPhoto(for type: PhotoType) -> ProgressPhoto? {
        photos.first { $0.typeEnum == type }
    }
    
    private func photoCount(for type: PhotoType) -> Int {
        photos.filter { $0.typeEnum == type }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("progress_photos.photo_types".localized)
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                ForEach(PhotoType.allCases, id: \.self) { type in
                    PhotoTypeCard(
                        type: type,
                        latestPhoto: latestPhoto(for: type),
                        count: photoCount(for: type)
                    )
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

struct PhotoTypeCard: View {
    let type: PhotoType
    let latestPhoto: ProgressPhoto?
    let count: Int
    
    var body: some View {
        VStack(spacing: 8) {
            // Photo Preview or Placeholder
            Group {
                if let latestPhoto = latestPhoto, let imageData = latestPhoto.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(width: 80, height: 100)
                        .overlay(
                            VStack {
                                Image(systemName: type.icon)
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                
                                Text("progress_photos.no_photo".localized)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        )
                }
            }
            
            VStack(spacing: 2) {
                Text(type.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("\(count) \("progress_photos.photos_count".localized)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Photo Timeline Section
struct PhotoTimelineSection: View {
    let groupedPhotos: [String: [ProgressPhoto]]
    let onDeletePhoto: (ProgressPhoto) -> Void
    
    private var sortedMonths: [String] {
        groupedPhotos.keys.sorted { month1, month2 in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            
            guard let date1 = formatter.date(from: month1),
                  let date2 = formatter.date(from: month2) else {
                return month1 > month2
            }
            
            return date1 > date2
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("progress_photos.timeline".localized)
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(sortedMonths, id: \.self) { month in
                if let monthPhotos = groupedPhotos[month] {
                    MonthSection(
                        month: month,
                        photos: monthPhotos,
                        onDeletePhoto: onDeletePhoto
                    )
                }
            }
        }
    }
}

struct MonthSection: View {
    let month: String
    let photos: [ProgressPhoto]
    let onDeletePhoto: (ProgressPhoto) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(month)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(photos) { photo in
                    PhotoGridItem(
                        photo: photo,
                        onDelete: { onDeletePhoto(photo) }
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct PhotoGridItem: View {
    let photo: ProgressPhoto
    let onDelete: () -> Void
    
    @State private var showingFullScreen = false
    
    var body: some View {
        VStack(spacing: 6) {
            // Photo
            Group {
                if let imageData = photo.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture {
                            showingFullScreen = true
                        }
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(height: 120)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        )
                }
            }
            
            // Info
            VStack(spacing: 2) {
                Text(photo.typeEnum.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(formatDate(photo.date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .contextMenu {
            Button {
                showingFullScreen = true
            } label: {
                Label("progress_photos.full_screen".localized, systemImage: "arrow.up.left.and.arrow.down.right")
            }
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("common.delete".localized, systemImage: "trash")
            }
        }
        .fullScreenCover(isPresented: $showingFullScreen) {
            if let imageData = photo.imageData,
               let uiImage = UIImage(data: imageData) {
                FullScreenPhotoView(image: uiImage, photo: photo)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Full Screen Photo View
struct FullScreenPhotoView: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage
    let photo: ProgressPhoto
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .pinchToZoom()
            }
            .navigationTitle(photo.typeEnum.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.close".localized) {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// Pinch to Zoom Extension
extension View {
    func pinchToZoom() -> some View {
        self.scaleEffect(1.0)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        // Handle zoom
                    }
            )
    }
}

// MARK: - Add Progress Photo View
struct AddProgressPhotoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Binding var selectedPhotoType: PhotoType
    let onPhotoAdded: () -> Void
    
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("progress_photos.add_photo".localized)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    // Photo Type Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("progress_photos.photo_type".localized)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 12) {
                            ForEach(PhotoType.allCases, id: \.self) { type in
                                Button {
                                    selectedPhotoType = type
                                } label: {
                                    VStack(spacing: 8) {
                                        Image(systemName: type.icon)
                                            .font(.title2)
                                            .foregroundColor(selectedPhotoType == type ? .white : type.color)
                                        
                                        Text(type.displayName)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(selectedPhotoType == type ? .white : .primary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(selectedPhotoType == type ? type.color : Color(.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }
                    
                    // Image Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Fotoğraf")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if let selectedImage = selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 300)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedPhotoType.color, lineWidth: 2)
                                )
                        } else {
                            Button {
                                showImageSourceSelection()
                            } label: {
                                VStack(spacing: 16) {
                                    Image(systemName: "camera.badge.plus")
                                        .font(.system(size: 40))
                                        .foregroundColor(.blue)
                                    
                                    Text("progress_photos.select_photo".localized)
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                    
                                    Text("progress_photos.camera_gallery".localized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
                                )
                            }
                        }
                    }
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("progress_photos.notes_optional".localized)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextField("progress_photos.notes_placeholder".localized, text: $notes, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    }
                }
                .padding()
            }
            .navigationTitle("progress_photos.add_photo".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.save".localized) {
                        savePhoto()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedImage == nil)
                }
            }
            .background(Color(.systemGroupedBackground))
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(
                selectedImage: $selectedImage,
                sourceType: sourceType
            )
        }
        .actionSheet(isPresented: $showingCamera) {
            ActionSheet(
                title: Text("progress_photos.select_source".localized),
                buttons: [
                    .default(Text("progress_photos.camera".localized)) {
                        sourceType = .camera
                        showingImagePicker = true
                    },
                    .default(Text("progress_photos.gallery".localized)) {
                        sourceType = .photoLibrary
                        showingImagePicker = true
                    },
                    .cancel()
                ]
            )
        }
    }
    
    private func showImageSourceSelection() {
        showingCamera = true
    }
    
    private func savePhoto() {
        guard let image = selectedImage,
              let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        let progressPhoto = ProgressPhoto(
            type: selectedPhotoType.rawValue,
            imageData: imageData,
            date: Date(),
            notes: notes.isEmpty ? nil : notes
        )
        
        modelContext.insert(progressPhoto)
        
        do {
            try modelContext.save()
            onPhotoAdded()
        } catch {
            print("Error saving photo: \(error)")
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    let sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    ProgressPhotosView()
}
