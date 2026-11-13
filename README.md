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
- **Game Booster**: Giao diện Cyberpunk Neon Gaming, đồng hồ đo độ sẵn sàng của máy (Readiness Score 0-100), nút BOOST NOW tối ưu bộ nhớ trước trận, cấu hình Gaming Presets (Balanced, Performance, Battery Saver, Gaming Focus), Checklist chuẩn bị, Thư viện Game (launch URL scheme), theo dõi phiên chơi game trực tiếp (Stopwatch HUD) và lưu trữ lịch sử phiên chơi.
- **Intro & Onboarding Walkthrough**: Màn hình AppSplashView với hiệu ứng hào quang & vòng xoay neon mượt mà, bộ thẻ Onboarding hướng dẫn người dùng lần đầu vào app (lưu trạng thái tự động bằng `@AppStorage`), và nút biểu tượng `info.circle` trên thanh tiêu đề Dashboard giúp xem lại phần giới thiệu mọi lúc.

Xem chi tiết kiến trúc và hướng dẫn xuất `.ipa` tại [ARCHITECTURE_AND_IPA_GUIDE.md](./ARCHITECTURE_AND_IPA_GUIDE.md).
