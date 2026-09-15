import SwiftUI

/// Central visual language for the app: a dark, high-contrast, "gym at
/// night" aesthetic with a single energetic accent (electric lime) plus
/// a secondary accent for balance/warnings. Reference AppTheme.* instead of
/// hardcoding colors anywhere else so the whole app can be restyled here.
enum AppTheme {
    // Backgrounds
    static let background = Color(red: 0.055, green: 0.06, blue: 0.07)
    static let surface = Color(red: 0.10, green: 0.11, blue: 0.125)
    static let surfaceElevated = Color(red: 0.14, green: 0.155, blue: 0.175)

    // Accents
    static let accent = Color(red: 0.74, green: 1.0, blue: 0.20)       // electric lime — primary actions, progress
    static let accentSecondary = Color(red: 0.35, green: 0.62, blue: 1.0) // cool blue — informational
    static let warning = Color(red: 1.0, green: 0.64, blue: 0.20)
    static let danger = Color(red: 1.0, green: 0.36, blue: 0.36)
    static let good = Color(red: 0.42, green: 0.92, blue: 0.55)

    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.62)
    static let textTertiary = Color.white.opacity(0.38)

    static let heroGradient = LinearGradient(
        colors: [Color(red: 0.74, green: 1.0, blue: 0.20), Color(red: 0.35, green: 0.85, blue: 0.55)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardCorner: CGFloat = 20
    static let smallCorner: CGFloat = 12

    static func color(for severity: InsightSeverity) -> Color {
        switch severity {
        case .good: return good
        case .notice: return accentSecondary
        case .warning: return warning
        }
    }
}

/// Reusable card container matching the app's dark elevated-surface style.
struct CardBackground: ViewModifier {
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
    }
}

extension View {
    func cardStyle(padding: CGFloat = 16) -> some View {
        modifier(CardBackground(padding: padding))
    }
}

/// A small rounded pill used for tags like equipment names or muscle groups.
struct TagView: View {
    let text: String
    var color: Color = AppTheme.textSecondary

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}
