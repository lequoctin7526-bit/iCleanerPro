import SwiftUI

/// Reusable dashboard card for metrics and quick feature navigation.
struct MetricCardView: View {
    let title: String
    let value: String
    let subtitle: String
    let iconName: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 36, height: 36)
                    .background(tint.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(value)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(tint)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumCard(cornerRadius: 18, padding: 14)
    }
}
