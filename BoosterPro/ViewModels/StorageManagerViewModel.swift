import Foundation
import Photos
import PhotosUI
import UIKit

@MainActor
final class StorageManagerViewModel: ObservableObject {
    @Published var storageInfo: DeviceStorageInfo = .empty
    @Published var photoPermission: PhotoPermissionState = .notDetermined
    @Published var largeMediaItems: [MediaAssetItem] = []
    @Published var duplicateGroups: [DuplicatePhotoGroup] = []
    @Published var managedFiles: [SandboxFileItem] = []

    @Published var largeMediaThresholdMB: Int64 = 10
    @Published var isScanningMedia = false
    @Published var scanProgress: Double = 0
    @Published var lastActionMessage: String?
    @Published var errorMessage: String?

    @Published var showFileImporter = false
    @Published var showDeleteMediaConfirmation = false
    @Published var showDeleteDuplicatesConfirmation = false
    @Published var showDeleteFilesConfirmation = false

    private let storageService = StorageManagerService()
    let photoService = PhotoAnalysisService()
    private let filePickerService = FilePickerService()

    func loadInitialState() {
        storageInfo = storageService.fetchDeviceStorageInfo()
        photoPermission = photoService.currentPermissionState()
        managedFiles = filePickerService.listManagedFiles()
    }

    func requestPhotosAccess() async {
        photoPermission = await photoService.requestPhotoPermission()
        if photoPermission.canAccessPhotos {
            await scanLargeMedia()
        }
    }

    func openLimitedLibraryPicker() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: rootVC)
    }

    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func scanLargeMedia() async {
        guard photoPermission.canAccessPhotos else { return }
        isScanningMedia = true
        scanProgress = 0
        errorMessage = nil
        defer { isScanningMedia = false }

        let thresholdBytes = largeMediaThresholdMB * 1_048_576
        let items = await photoService.scanLargeMedia(minimumBytes: thresholdBytes) { progress in
            Task { @MainActor in
                self.scanProgress = progress
            }
        }
        largeMediaItems = items
    }

    func scanDuplicates() async {
        guard photoPermission.canAccessPhotos else { return }
        isScanningMedia = true
        scanProgress = 0
        errorMessage = nil
        defer { isScanningMedia = false }

        let groups = await photoService.scanDuplicatePhotos(maxAssetsToAnalyze: 500) { progress in
            Task { @MainActor in
                self.scanProgress = progress
            }
        }
        duplicateGroups = groups
    }

    func toggleLargeMediaSelection(id: String) {
        guard let idx = largeMediaItems.firstIndex(where: { $0.id == id }) else { return }
        largeMediaItems[idx].isSelected.toggle()
    }

    func toggleDuplicateSelection(groupID: UUID, assetID: String) {
        guard let gIdx = duplicateGroups.firstIndex(where: { $0.id == groupID }),
              let aIdx = duplicateGroups[gIdx].assets.firstIndex(where: { $0.id == assetID }) else {
            return
        }
        duplicateGroups[gIdx].assets[aIdx].isSelected.toggle()
    }

    var selectedLargeMedia: [MediaAssetItem] {
        largeMediaItems.filter(\.isSelected)
    }

    var selectedLargeMediaBytes: Int64 {
        selectedLargeMedia.reduce(0) { $0 + $1.fileSizeBytes }
    }

    var selectedDuplicateAssets: [MediaAssetItem] {
        duplicateGroups.flatMap(\.assets).filter(\.isSelected)
    }

    var selectedDuplicateBytes: Int64 {
        selectedDuplicateAssets.reduce(0) { $0 + $1.fileSizeBytes }
    }

    func deleteConfirmedLargeMedia() async {
        let targets = selectedLargeMedia
        guard !targets.isEmpty else { return }
        do {
            let freed = try await photoService.deleteAssets(targets)
            let deletedIDs = Set(targets.map(\.id))
            largeMediaItems.removeAll { deletedIDs.contains($0.id) }
            storageInfo = storageService.fetchDeviceStorageInfo()
            lastActionMessage = "Đã xóa \(targets.count) tệp media (giải phóng ~ \(ByteFormatterUtil.formatFileSize(freed)))."
        } catch {
            errorMessage = "Không thể xóa ảnh/video: \(error.localizedDescription)"
        }
    }

    func deleteConfirmedDuplicates() async {
        let targets = selectedDuplicateAssets
        guard !targets.isEmpty else { return }
        do {
            let freed = try await photoService.deleteAssets(targets)
            let deletedIDs = Set(targets.map(\.id))
            for idx in duplicateGroups.indices {
                duplicateGroups[idx].assets.removeAll { deletedIDs.contains($0.id) }
            }
            duplicateGroups.removeAll { $0.assets.count <= 1 }
            storageInfo = storageService.fetchDeviceStorageInfo()
            lastActionMessage = "Đã xóa \(targets.count) ảnh trùng lặp (giải phóng ~ \(ByteFormatterUtil.formatFileSize(freed)))."
        } catch {
            errorMessage = "Không thể xóa ảnh trùng lặp: \(error.localizedDescription)"
        }
    }

    // MARK: - Files Picker Management
    func handlePickedFiles(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            do {
                managedFiles = try filePickerService.importPickedFiles(urls: urls)
                storageInfo = storageService.fetchDeviceStorageInfo()
                lastActionMessage = "Đã thêm \(urls.count) tệp vào trình quản lý tệp."
            } catch {
                errorMessage = "Không thể nhập tệp: \(error.localizedDescription)"
            }
        case .failure(let error):
            errorMessage = "Lỗi chọn tệp: \(error.localizedDescription)"
        }
    }

    func toggleManagedFileSelection(id: UUID) {
        guard let idx = managedFiles.firstIndex(where: { $0.id == id }) else { return }
        managedFiles[idx].isSelected.toggle()
    }

    var selectedManagedFiles: [SandboxFileItem] {
        managedFiles.filter(\.isSelected)
    }

    var selectedManagedFilesBytes: Int64 {
        selectedManagedFiles.reduce(0) { $0 + $1.sizeBytes }
    }

    func deleteSelectedManagedFiles() {
        let count = selectedManagedFiles.count
        guard count > 0 else { return }
        let freed = filePickerService.deleteManagedFiles(managedFiles)
        managedFiles = filePickerService.listManagedFiles()
        storageInfo = storageService.fetchDeviceStorageInfo()
        lastActionMessage = "Đã xóa \(count) tệp đã chọn (giải phóng \(ByteFormatterUtil.formatFileSize(freed)))."
    }
}
