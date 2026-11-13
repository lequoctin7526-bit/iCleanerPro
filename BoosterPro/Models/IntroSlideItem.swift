import SwiftUI

/// Represents a page in the onboarding intro walkthrough.
struct IntroSlideItem: Identifiable, Hashable {
    let id: Int
    let badgeText: String
    let title: String
    let subtitle: String
    let highlightFeature: String
    let iconName: String
    let gradientColors: [Color]

    static let defaultSlides: [IntroSlideItem] = [
        IntroSlideItem(
            id: 0,
            badgeText: "CHÀO MỪNG BẠN",
            title: "Booster Pro",
            subtitle: "Bộ công cụ dọn dẹp & tối ưu thiết bị Apple chuẩn mực, hiện đại và minh bạch.",
            highlightFeature: "100% sử dụng Apple Public API, không quảng cáo rác, không tạo số liệu giả lập.",
            iconName: "sparkles.rectangle.stack.fill",
            gradientColors: [Color(red: 0.14, green: 0.45, blue: 0.98), Color(red: 0.08, green: 0.72, blue: 0.85)]
        ),
        IntroSlideItem(
            id: 1,
            badgeText: "DỌN RÁC AN TOÀN",
            title: "Clean Junk & Cache",
            subtitle: "Quét sạch tệp tạm sandbox, log phiên cũ và bộ nhớ đệm dư thừa của ứng dụng.",
            highlightFeature: "Tuyệt đối không xóa dữ liệu đăng nhập, cài đặt hoặc tài liệu quan trọng của bạn.",
            iconName: "trash.slash.fill",
            gradientColors: [Color(red: 0.96, green: 0.35, blue: 0.25), Color(red: 0.98, green: 0.62, blue: 0.15)]
        ),
        IntroSlideItem(
            id: 2,
            badgeText: "TIẾT KIỆM BỘ NHỚ",
            title: "Storage & Duplicate Photos",
            subtitle: "Tích hợp Apple Vision & PhotoKit tìm ảnh tương tự, ảnh chụp liên tiếp và video dung lượng lớn.",
            highlightFeature: "Xử lý trực tiếp trên thiết bị (On-Device) bảo mật cao, luôn yêu cầu xác nhận trước khi xóa.",
            iconName: "photo.on.rectangle.angled",
            gradientColors: [Color(red: 0.55, green: 0.25, blue: 0.98), Color(red: 0.25, green: 0.55, blue: 0.98)]
        ),
        IntroSlideItem(
            id: 3,
            badgeText: "GAMING MODE MỚI",
            title: "Game Booster Cyberpunk",
            subtitle: "HUD gaming chuyên nghiệp, đồng hồ đo độ sẵn sàng thiết bị và cấu hình Gaming Presets.",
            highlightFeature: "Tối ưu hóa bộ nhớ trước trận, theo dõi nhiệt độ và bấm giờ thời gian thi đấu trực tiếp.",
            iconName: "gamecontroller.fill",
            gradientColors: [Color(red: 0.0, green: 0.98, blue: 0.58), Color(red: 0.0, green: 0.88, blue: 0.98)]
        )
    ]
}
