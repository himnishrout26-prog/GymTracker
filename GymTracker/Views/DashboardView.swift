import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile { profiles.first ?? UserProfile() }

    private var thisWeekSessions: [WorkoutSession] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        return sessions.filter { $0.date >= cutoff }
    }

    private var totalVolumeThisWeek: Double {
        thisWeekSessions.reduce(0) { $0 + $1.totalVolume }
    }

    private var streakDays: Int {
        var streak = 0
        var cursor = Calendar.current.startOfDay(for: .now)
        let sessionDays = Set(sessions.map { Calendar.current.startOfDay(for: $0.date) })
        while sessionDays.contains(cursor) {
            streak += 1
            cursor = Calendar.current.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        return streak
    }

    private var topInsight: TrainingInsight? {
        WorkoutAnalyzer(sessions: sessions, profile: profile).generateInsights().first
    }

    private var last14DaysVolume: [(Date, Double)] {
        let calendar = Calendar.current
        let days = (0..<14).map { calendar.date(byAdding: .day, value: -$0, to: calendar.startOfDay(for: .now))! }.reversed()
        return days.map { day in
            let vol = sessions
                .filter { calendar.isDate($0.date, inSameDayAs: day) }
                .reduce(0.0) { $0 + $1.totalVolume }
            return (day, vol)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            StatCard(title: "Sessions this week", value: "\(thisWeekSessions.count)", subtitle: "Target: \(profile.daysAvailablePerWeek)/wk", accent: AppTheme.accent, icon: "flame.fill")
                            StatCard(title: "Day streak", value: "\(streakDays)", subtitle: streakDays > 0 ? "Keep it going" : "Log today to start one", accent: AppTheme.accentSecondary, icon: "bolt.fill")
                            StatCard(title: "Volume this week", value: formattedVolume(totalVolumeThisWeek), subtitle: "kg lifted", accent: AppTheme.good, icon: "scalemass.fill")
                            StatCard(title: "Total sessions", value: "\(sessions.count)", subtitle: "All time", accent: AppTheme.warning, icon: "calendar")
                        }

                        volumeChart

                        if let topInsight {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Top Insight").font(.headline).foregroundStyle(AppTheme.textPrimary)
                                NavigationLink {
                                    AnalysisView()
                                } label: {
                                    InsightRow(insight: topInsight)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        recentSessions
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Overview")
            .toolbarBackground(AppTheme.background, for: .navigationBar)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(.title2.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
            Text(profile.goal.displayName + " • " + profile.experience.displayName)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        let base = hour < 12 ? "Good morning" : (hour < 18 ? "Good afternoon" : "Good evening")
        return "\(base), \(profile.name)"
    }

    private var volumeChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Volume — last 14 days").font(.headline).foregroundStyle(AppTheme.textPrimary)
            Chart {
                ForEach(last14DaysVolume, id: \.0) { entry in
                    BarMark(
                        x: .value("Day", entry.0, unit: .day),
                        y: .value("Volume", entry.1)
                    )
                    .foregroundStyle(AppTheme.accent.gradient)
                    .cornerRadius(4)
                }
            }
            .frame(height: 160)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 3)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine().foregroundStyle(AppTheme.textTertiary.opacity(0.2))
                    AxisValueLabel().foregroundStyle(AppTheme.textTertiary)
                }
            }
        }
        .cardStyle()
    }

    private var recentSessions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Sessions").font(.headline).foregroundStyle(AppTheme.textPrimary)
            if sessions.isEmpty {
                Text("No sessions yet — log your first workout from the Log tab.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .cardStyle()
            } else {
                ForEach(sessions.prefix(5)) { session in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.name).font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.textPrimary)
                            Text(session.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(session.sets.count) sets").font(.caption.weight(.medium)).foregroundStyle(AppTheme.accent)
                            Text(formattedVolume(session.totalVolume) + " kg").font(.caption2).foregroundStyle(AppTheme.textTertiary)
                        }
                    }
                    .cardStyle(padding: 14)
                }
            }
        }
    }

    private func formattedVolume(_ v: Double) -> String {
        v >= 1000 ? String(format: "%.1fk", v / 1000) : String(format: "%.0f", v)
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Exercise.self, WorkoutSession.self, SetEntry.self, UserProfile.self], inMemory: true)
}
