import SwiftUI

/// Modern premium onboarding walkthrough view for first-time launch or replay.
struct OnboardingIntroView: View {
    let onFinish: () -> Void

    @State private var currentIndex: Int = 0
    private let slides = IntroSlideItem.defaultSlides

    var body: some View {
        ZStack {
            // Elegant background
            AppTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                TabView(selection: $currentIndex) {
                    ForEach(slides) { slide in
                        slideContent(for: slide)
                            .tag(slide.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentIndex)

                bottomBar
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .padding(.top, 12)
            }
        }
    }

    // MARK: - Subviews

    private var topBar: some View {
        HStack {
            if currentIndex > 0 {
                Button {
                    withAnimation {
                        currentIndex -= 1
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 38, height: 38)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Trang trước")
            } else {
                Spacer()
                    .frame(width: 38, height: 38)
            }

            Spacer()

            if currentIndex < slides.count - 1 {
                Button("Bỏ qua") {
                    onFinish()
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.secondary.opacity(0.10))
                .clipShape(Capsule())
            }
        }
    }

    private func slideContent(for slide: IntroSlideItem) -> some View {
        VStack(spacing: 24) {
            Spacer()

            // Visual Hero Icon with layered glowing gradient
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [slide.gradientColors.first?.opacity(0.35) ?? .blue.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 130
                        )
                    )
                    .frame(width: 220, height: 220)

                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: slide.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: (slide.gradientColors.first ?? .blue).opacity(0.4), radius: 18, x: 0, y: 10)

                Image(systemName: slide.iconName)
                    .font(.system(size: 54, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 12)

            // Badge
            Text(slide.badgeText)
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .foregroundStyle(slide.gradientColors.first ?? AppTheme.primaryAccent)
                .tracking(1.2)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background((slide.gradientColors.first ?? AppTheme.primaryAccent).opacity(0.15))
                .clipShape(Capsule())

            // Title & Subtitle
            VStack(spacing: 10) {
                Text(slide.title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                Text(slide.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 20)
            }

            // Highlight feature card
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title3)
                    .foregroundStyle(slide.gradientColors.first ?? AppTheme.optimalGreen)

                Text(slide.highlightFeature)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineSpacing(2)

                Spacer(minLength: 0)
            }
            .padding(14)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
            )
            .padding(.horizontal, 28)

            Spacer()
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 20) {
            // Page Indicator Pills
            HStack(spacing: 8) {
                ForEach(slides) { slide in
                    Capsule()
                        .fill(currentIndex == slide.id ? (slide.gradientColors.first ?? AppTheme.primaryAccent) : Color.secondary.opacity(0.25))
                        .frame(width: currentIndex == slide.id ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentIndex)
                }
            }

            // Action Button
            Button {
                if currentIndex < slides.count - 1 {
                    withAnimation {
                        currentIndex += 1
                    }
                } else {
                    onFinish()
                }
            } label: {
                HStack(spacing: 8) {
                    Text(currentIndex < slides.count - 1 ? "Tiếp tục" : "Bắt đầu ngay")
                        .font(.headline.weight(.bold))
                    Image(systemName: currentIndex < slides.count - 1 ? "arrow.right" : "sparkles")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        colors: slides[currentIndex].gradientColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: (slides[currentIndex].gradientColors.first ?? .blue).opacity(0.35), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(.plain)

            // Creator Attribution & Facebook Link
            HStack(spacing: 8) {
                Text(DeveloperInfo.appCreatedBy)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)

                Text("•")
                    .font(.caption2)
                    .foregroundStyle(.secondary.opacity(0.4))

                Link(destination: URL(string: DeveloperInfo.facebookURL)!) {
                    HStack(spacing: 4) {
                        Image(systemName: "link.circle.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("Facebook")
                            .font(.caption2.bold())
                    }
                    .foregroundStyle(AppTheme.primaryAccent)
                }
            }
            .padding(.top, 2)
        }
    }
}
