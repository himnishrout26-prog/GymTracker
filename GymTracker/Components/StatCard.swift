import SwiftUI

/// Compact metric card for the dashboard grid (e.g. "This Week: 4 sessions").
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    var accent: Color = AppTheme.accent
    var icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(accent)
                Spacer()
            }
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)
            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

/// A single row in the "Is my training optimal?" insight feed.
struct InsightRow: View {
    let insight: TrainingInsight

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.color(for: insight.severity).opacity(0.16))
                    .frame(width: 40, height: 40)
                Image(systemName: insight.sfSymbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.color(for: insight.severity))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(insight.detail)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .cardStyle()
    }
}

/// Horizontal bar showing weekly sets for one muscle group against its
/// recommended range — the visual core of the volume-analysis screen.
struct MuscleVolumeBar: View {
    let entry: MuscleGroupVolume

    private var maxScale: CGFloat { CGFloat(max(entry.recommendedRange.upperBound, entry.weeklySets)) + 4 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.muscle.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text("\(entry.weeklySets) sets")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.color(for: entry.status))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppTheme.surfaceElevated)

                    // recommended range band
                    let rangeStart = CGFloat(entry.recommendedRange.lowerBound) / maxScale * geo.size.width
                    let rangeWidth = CGFloat(entry.recommendedRange.upperBound - entry.recommendedRange.lowerBound) / maxScale * geo.size.width
                    Capsule()
                        .fill(AppTheme.textTertiary.opacity(0.25))
                        .frame(width: max(rangeWidth, 2))
                        .offset(x: rangeStart)

                    // actual value
                    Capsule()
                        .fill(AppTheme.color(for: entry.status))
                        .frame(width: max(CGFloat(entry.weeklySets) / maxScale * geo.size.width, entry.weeklySets > 0 ? 6 : 0))
                }
            }
            .frame(height: 10)
        }
    }
}
