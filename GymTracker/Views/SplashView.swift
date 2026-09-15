import SwiftUI

/// Brief branded splash shown on cold launch before the main tab bar appears.
struct SplashView: View {
    @State private var animateIn = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            VStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(AppTheme.heroGradient)
                        .frame(width: 96, height: 96)
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(.black)
                }
                .scaleEffect(animateIn ? 1 : 0.7)
                .opacity(animateIn ? 1 : 0)

                Text("GymTracker")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .opacity(animateIn ? 1 : 0)

                Text("Made by Himnish")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .opacity(animateIn ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.7)) {
                animateIn = true
            }
        }
    }
}

#Preview {
    SplashView()
}
