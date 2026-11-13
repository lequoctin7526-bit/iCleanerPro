# iCleaner Pro (iOS 16+ SwiftUI)

Ứng dụng iOS dọn dẹp và tối ưu thiết bị xây dựng bằng **Swift + SwiftUI (MVVM)**, sử dụng 100% Apple Public APIs, không Private API, không số liệu giả.

## Tính năng chính
- **Dashboard**: Vòng tròn điểm tối ưu, tình trạng nhiệt độ/CPU, biểu đồ dung lượng lưu trữ, RAM khả dụng, dung lượng cache và điều hướng nhanh.
- **Smart Scan & Result**: Hiệu ứng radar quét hệ thống theo thời gian thực, phân loại dữ liệu tìm được, chọn hạng mục cần dọn, màn hình kết quả Before/After và tổng dung lượng giải phóng thực tế.
- **Junk Cleaner**: Quét và dọn file tạm (`tmp/`), log (`Library/Logs`), cache dư thừa và file dung lượng lớn trong sandbox; phân loại theo loại & mức dung lượng.
- **Device Booster**: Giám sát CPU tiến trình qua Mach `thread_info`, nhiệt độ máy, Low Power Mode, phát hiện yếu tố làm chậm và chạy tối ưu hóa an toàn.
- **RAM Cleaner**: Đo RAM hệ thống thật (`host_statistics64`), App Footprint (`TASK_VM_INFO`) và giải phóng `NSCache`/`URLCache`/`PHCachingImageManager`.
- **Cache Cleaner**: Phân biệt rõ vùng Cache an toàn có thể xóa và Dữ liệu người dùng được bảo vệ.
- **Storage Manager**: Tích hợp **PhotoKit** (Full & Limited Access), tìm ảnh trùng lặp bằng **dHash + Vision FeaturePrint**, tìm ảnh/video dung lượng lớn, và quản lý tệp qua **Files Picker (`.fileImporter`)**.

Xem chi tiết kiến trúc và hướng dẫn xuất `.ipa` tại [ARCHITECTURE_AND_IPA_GUIDE.md](./ARCHITECTURE_AND_IPA_GUIDE.md).
