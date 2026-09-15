import SwiftUI
import SwiftData
import Charts

struct ExerciseDetailView: View {
    let exercise: Exercise
    @Query(sort: \WorkoutSession.date) private var sessions: [WorkoutSession]
    @Query private var profiles: [UserProfile]

    private var progress: [ExerciseProgressPoint] {
        WorkoutAnalyzer(sessions: sessions, profile: profiles.first ?? UserProfile()).progressionTrend(for: exercise)
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    AsyncImage(url: exercise.imageURL) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Rectangle().fill(AppTheme.surfaceElevated)
                                .overlay(Image(systemName: "figure.strengthtraining.traditional").font(.system(size: 36)).foregroundStyle(AppTheme.textTertiary))
                        }
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))

                    Text(exercise.name)
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.textPrimary)

                    HStack(spacing: 8) {
                        TagView(text: exercise.primaryMuscle.displayName, color: AppTheme.accentSecondary)
                        ForEach(exercise.secondaryMuscles) { muscle in
                            TagView(text: muscle.displayName)
                        }
                    }

                    if !exercise.equipment.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(exercise.equipment, id: \.self) { eq in
                                TagView(text: eq, color: AppTheme.warning)
                            }
                        }
                    }

                    if !exercise.exerciseDescription.isEmpty {
                        Text(exercise.exerciseDescription)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    if progress.count >= 2 {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Your Progress (est. 1RM)").font(.headline).foregroundStyle(AppTheme.textPrimary)
                            Chart(progress) { point in
                                LineMark(x: .value("Date", point.date), y: .value("1RM", point.estimated1RM))
                                    .foregroundStyle(AppTheme.accent)
                                    .interpolationMethod(.catmullRom)
                                PointMark(x: .value("Date", point.date), y: .value("1RM", point.estimated1RM))
                                    .foregroundStyle(AppTheme.accent)
                            }
                            .frame(height: 160)
                            .chartYAxis { AxisMarks { _ in AxisGridLine().foregroundStyle(AppTheme.textTertiary.opacity(0.2)); AxisValueLabel().foregroundStyle(AppTheme.textTertiary) } }
                            .chartXAxis { AxisMarks { _ in AxisValueLabel().foregroundStyle(AppTheme.textTertiary) } }
                        }
                        .cardStyle()
                    } else {
                        Text("Log this exercise a couple more times to see your progress trend here.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textTertiary)
                            .cardStyle()
                    }
                }
                .padding(20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
