# iCleaner Pro — Phân Tích Kiến Trúc, Giới Hạn Kỹ Thuật iOS & Hướng Dẫn Xuất File `.ipa`

## 1. Kiến trúc hệ thống (MVVM + Modular Services)

Ứng dụng **iCleaner Pro** được xây dựng theo kiến trúc **MVVM (Model – View – ViewModel)** kết hợp tầng **Services** tách biệt hoàn toàn với giao diện SwiftUI, tương thích **iOS 16.0+**, sử dụng 100% API công khai của Apple (`Foundation`, `SwiftUI`, `Darwin.Mach`, `os.proc`, `Photos`, `Vision`, `CryptoKit`, `UniformTypeIdentifiers`, `UIKit`).

```text
Views (SwiftUI) ──▶ ViewModels (@MainActor ObservableObject) ──▶ Services (Domain Logic) ──▶ Apple Public Frameworks
```

---

## 2. Phân tích giới hạn kỹ thuật của iOS (Non-Jailbreak) & Phương án triển khai hợp lệ

Hệ điều hành iOS áp dụng mô hình **App Sandbox** và cơ chế quản lý tiến trình/bộ nhớ nghiêm ngặt nhằm bảo vệ quyền riêng tư và ổn định hệ thống. Dưới đây là chi tiết giới hạn thực tế và cách **iCleaner Pro** xử lý hợp lệ 100%:

| Chức năng | Giới hạn kỹ thuật iOS (Không Jailbreak) | Phương án hợp lệ triển khai trong iCleaner Pro |
| :--- | :--- | :--- |
| **Dọn dẹp rác (Junk Cleaner)** | Ứng dụng không thể truy cập `/var/mobile` hay thư mục container của ứng dụng khác. | Quét và tính dung lượng thực tế bằng `URLResourceValues` trong toàn bộ Sandbox ứng dụng (`tmp/`, `Library/Caches/`, `Library/Logs/`, `Documents/Staging`, `Documents/Downloads`), phân loại theo loại & ngưỡng dung lượng (`<1MB`, `1-10MB`, `10-50MB`, `>50MB`), xóa chọn lọc và đo lại dung lượng giải phóng thực tế. |
| **Tăng tốc thiết bị (Device Booster)** | Public API không cho phép kill tiến trình ứng dụng khác hay thay đổi xung nhịp CPU phần cứng. | Dùng Mach `task_threads` + `thread_info(THREAD_BASIC_INFO)` để đo CPU thật của ứng dụng, `ProcessInfo.thermalState`, `isLowPowerModeEnabled`, `UIDevice.batteryLevel`, `UIScreen.brightness`; phân tích nguyên nhân gây chậm thực tế (nóng máy, bộ nhớ trống < 15%, áp lực RAM, Low Power Mode) và thực thi quy trình tối ưu an toàn nội bộ. |
| **Dọn RAM (RAM Cleaner)** | iOS Jetsam tự quản lý RAM vật lý toàn cục; không thể ép xóa RAM của tiến trình khác. | Dùng `host_statistics64(HOST_VM_INFO64)`, `task_info(TASK_VM_INFO)` và `os_proc_available_memory()` để hiển thị phân bổ RAM thật (`Wired`, `Active`, `Compressed`, `Inactive`, `Free`, `App Footprint`). Giải phóng `NSCache`, `URLCache`, `PHCachingImageManager` trong `autoreleasepool` và đo lại sự thay đổi `phys_footprint` trước/sau. |
| **Dọn bộ nhớ đệm (Cache Cleaner)** | Không có quyền xóa cache của Safari hoặc ứng dụng bên thứ ba. | Phân tách rõ **Cache có thể xóa** (`URLCache`, `Thumbnails`, `tmp/`, `Logs`) với **Dữ liệu được bảo vệ** (`Library/Preferences`, `Documents/ManagedFiles`) để tuyệt đối không làm mất cài đặt hay dữ liệu người dùng. |
| **Quản lý dung lượng (Storage Manager)** | Cần quyền do người dùng cấp cho Ảnh/Video và File ngoài sandbox. | Đọc dung lượng thiết bị từ `volumeTotalCapacityKey` / `volumeAvailableCapacityForImportantUsageKey`; tích hợp **PhotoKit** (hỗ trợ cả Full và Limited Access), phát hiện ảnh trùng lặp bằng **dHash (CoreGraphics)** + **Apple Vision FeaturePrint**, lọc video/ảnh lớn, tích hợp **Files Picker (`.fileImporter`)**, luôn yêu cầu xác nhận trước khi xóa. |

---

## 3. Cấu hình Xcode & Hướng dẫn xuất file `.ipa`

> **Lưu ý môi trường build**: Biên dịch iOS `.xcarchive` và xuất `.ipa` yêu cầu **macOS với Xcode 15+** (hoặc dùng GitHub Actions macOS runner được cấu hình sẵn tại `.github/workflows/build-ipa.yml`).

### Cách 1: Xuất `.ipa` bằng Xcode GUI (Khuyên dùng)
1. Mở file `iCleanerPro.xcodeproj` trên máy Mac bằng Xcode 15+.
2. Chọn target **iCleanerPro** → tab **Signing & Capabilities**:
   - Đánh dấu **Automatically manage signing**.
   - Chọn **Team** (Apple Developer Account).
   - Xác nhận **Bundle Identifier**: `com.icleanerpro.app` (hoặc đổi theo domain của bạn).
   - Xác nhận **iOS Deployment Target**: `16.0`.
3. Ở thanh chọn thiết bị trên cùng, chọn **Any iOS Device (arm64)** (không chọn Simulator).
4. Trên thanh menu, chọn **Product → Archive** (cấu hình **Release** đã được đặt mặc định cho Archive trong `iCleanerPro.xcscheme`).
5. Khi cửa sổ **Organizer** mở ra, nhấn **Distribute App**:
   - Chọn **Development** (cài test qua Xcode/Apple Configurator), **Ad Hoc** (phân phối nội bộ qua UDID), hoặc **App Store Connect** (TestFlight / App Store).
   - Chọn Certificate & Provisioning Profile hợp lệ → nhấn **Export** để nhận file `iCleanerPro.ipa`.

### Cách 2: Xuất `.ipa` bằng dòng lệnh (`scripts/build_ipa.sh`)
```bash
chmod +x scripts/build_ipa.sh

# Xuất IPA đã ký bằng Development / Distribution Profile (chỉnh ExportOptions.plist)
./scripts/build_ipa.sh

# Hoặc tạo bản IPA chưa ký để kiểm tra đóng gói Payload
./scripts/build_ipa.sh --unsigned
```

### Cách 3: Tự động build `.ipa` trên Cloud bằng GitHub Actions
File `.github/workflows/build-ipa.yml` đã được thiết lập sẵn chạy trên `macos-14`:
- Tự động chạy Unit Tests (`iCleanerProTests`).
- Tự động Archive Release và đóng gói thành `iCleanerPro-unsigned.ipa` trong mục Artifacts.
