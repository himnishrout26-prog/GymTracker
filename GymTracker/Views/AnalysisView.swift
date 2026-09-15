import SwiftUI
import SwiftData

struct AnalysisView: View {
    @Query(sort: \WorkoutSession.date) private var sessions: [WorkoutSession]
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile { profiles.first ?? UserProfile() }
    private var analyzer: WorkoutAnalyzer { WorkoutAnalyzer(sessions: sessions, profile: profile) }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                if sessions.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            summaryHeader

                            VStack(alignment: .leading, spacing: 10) {
                                Text("Insights").font(.headline).foregroundStyle(AppTheme.textPrimary)
                                ForEach(analyzer.generateInsights()) { insight in
                                    InsightRow(insight: insight)
                                }
                            }

                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    Text("Weekly Volume by Muscle").font(.headline).foregroundStyle(AppTheme.textPrimary)
                                    Spacer()
                                }
                                Text("Shaded band = typical range for your experience level")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.textTertiary)
                                VStack(spacing: 16) {
                                    ForEach(analyzer.weeklyVolumeByMuscle()) { entry in
                                        MuscleVolumeBar(entry: entry)
                                    }
                                }
                                .cardStyle()
                            }

                            disclaimer
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Analysis")
        }
    }

    private var summaryHeader: some View {
        let insights = analyzer.generateInsights()
        let warnings = insights.filter { $0.severity == .warning }.count
        let goods = insights.filter { $0.severity == .good }.count

        return HStack(spacing: 14) {
            scoreBadge(count: goods, label: "On Track", color: AppTheme.good)
            scoreBadge(count: insights.count - warnings - goods, label: "Worth Noting", color: AppTheme.accentSecondary)
            scoreBadge(count: warnings, label: "Needs Attention", color: AppTheme.warning)
        }
    }

    private func scoreBadge(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text("\(count)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .cardStyle(padding: 10)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.textTertiary)
            Text("No analysis yet")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            Text("Log a few workouts and this tab will tell you whether your training volume, balance, and progression look on track.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private var disclaimer: some View {
        Text("These are general training-science guidelines, not medical or professional coaching advice. If you have pain, an injury, or a health condition, check with a doctor or physical therapist before changing your program.")
            .font(.caption2)
            .foregroundStyle(AppTheme.textTertiary)
            .padding(.top, 4)
    }
}

#Preview {
    AnalysisView()
        .modelContainer(for: [Exercise.self, WorkoutSession.self, SetEntry.self, UserProfile.self], inMemory: true)
}
