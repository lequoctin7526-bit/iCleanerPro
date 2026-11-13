import SwiftUI

/// Consistent banner displaying idle, scanning, completed, or error states with optional retry action.
struct StatusStateBanner: View {
    let phase: ScanPhase
    var detailText: String?
    var onRetry: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            statusIcon

            VStack(alignment: .leading, spacing: 2) {
                Text(phase.statusLabel)
                    .font(.subheadline.weight(.semibold))
                if let detailText, !detailText.isEmpty {
                    Text(detailText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if case .error = phase, let onRetry {
                Button("Thử lại", action: onRetry)
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
        .padding(14)
        .background(bannerTint.opacity(0.11))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(bannerTint.opacity(0.25), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch phase {
        case .idle:
            Image(systemName: "checkmark.shield")
                .font(.title3)
                .foregroundStyle(AppTheme.primaryAccent)
        case .scanningStorage, .scanningJunk, .scanningCache, .scanningMemory, .scanningDeviceHealth, .cleaning:
            ProgressView()
                .tint(AppTheme.primaryAccent)
        case .completed, .cleaned:
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(AppTheme.optimalGreen)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(AppTheme.criticalRed)
        }
    }

    private var bannerTint: Color {
        switch phase {
        case .idle, .scanningStorage, .scanningJunk, .scanningCache, .scanningMemory, .scanningDeviceHealth, .cleaning:
            return AppTheme.primaryAccent
        case .completed, .cleaned:
            return AppTheme.optimalGreen
        case .error:
            return AppTheme.criticalRed
        }
    }
}
