import Foundation

enum InsightSeverity: String {
    case good       // things are on track
    case notice     // worth knowing, not urgent
    case warning    // should probably change something

    var sortWeight: Int {
        switch self {
        case .warning: return 0
        case .notice: return 1
        case .good: return 2
        }
    }
}

struct TrainingInsight: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let severity: InsightSeverity
    let sfSymbol: String
}

struct MuscleGroupVolume: Identifiable {
    let id = UUID()
    let muscle: MuscleGroup
    let weeklySets: Int
    let recommendedRange: ClosedRange<Int>

    var status: InsightSeverity {
        if weeklySets == 0 { return .notice }
        if recommendedRange.contains(weeklySets) { return .good }
        return .warning
    }
}

struct ExerciseProgressPoint: Identifiable {
    let id = UUID()
    let date: Date
    let estimated1RM: Double
}

/// Turns raw logged sessions into plain-language, actionable feedback.
///
/// This is a heuristic engine built on well-established, general training
/// principles (progressive overload, weekly volume landmarks, recovery
/// spacing, rep ranges matched to goal). It is NOT a substitute for a coach,
/// physical therapist, or doctor — especially around pain, injury, or
/// medical conditions. Keep that framing in any UI that surfaces this.
struct WorkoutAnalyzer {
    let sessions: [WorkoutSession]
    let profile: UserProfile

    /// Sessions from the last 7 days, most recent first.
    private var lastWeekSessions: [WorkoutSession] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        return sessions.filter { $0.date >= cutoff }.sorted { $0.date > $1.date }
    }

    private var last28DaySessions: [WorkoutSession] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -28, to: .now) ?? .now
        return sessions.filter { $0.date >= cutoff }.sorted { $0.date > $1.date }
    }

    // MARK: - Weekly volume per muscle group

    func weeklyVolumeByMuscle() -> [MuscleGroupVolume] {
        var setCounts: [MuscleGroup: Int] = [:]
        for session in lastWeekSessions {
            for set in session.sets where !set.isWarmup {
                guard let muscle = set.exercise?.primaryMuscle, muscle != .fullBody else { continue }
                setCounts[muscle, default: 0] += 1
            }
        }
        let landmarks = profile.experience.weeklySetLandmarks
        let range = landmarks.min...landmarks.max
        // Show every group that has at least some data, plus the "major" groups
        // even at zero so gaps are visible.
        let majorGroups: [MuscleGroup] = [.chest, .back, .shoulders, .quads, .hamstrings, .glutes, .biceps, .triceps, .core]
        let allGroups = Set(majorGroups).union(setCounts.keys)
        return allGroups
            .map { MuscleGroupVolume(muscle: $0, weeklySets: setCounts[$0] ?? 0, recommendedRange: range) }
            .sorted { $0.weeklySets > $1.weeklySets }
    }

    // MARK: - Progressive overload trend for one exercise

    func progressionTrend(for exercise: Exercise) -> [ExerciseProgressPoint] {
        sessions
            .sorted { $0.date < $1.date }
            .compactMap { session -> ExerciseProgressPoint? in
                let sets = session.sets.filter { $0.exercise?.id == exercise.id && !$0.isWarmup }
                guard let best = sets.map({ $0.estimated1RM }).max() else { return nil }
                return ExerciseProgressPoint(date: session.date, estimated1RM: best)
            }
    }

    // MARK: - Headline insights

    /// The main "is this optimal?" feed: a ranked list of plain-language
    /// observations, worst issues first.
    func generateInsights() -> [TrainingInsight] {
        var insights: [TrainingInsight] = []

        insights.append(contentsOf: frequencyInsights())
        insights.append(contentsOf: volumeInsights())
        insights.append(contentsOf: balanceInsights())
        insights.append(contentsOf: repRangeInsights())
        insights.append(contentsOf: recoveryInsights())
        insights.append(contentsOf: progressionInsights())

        return insights.sorted { $0.severity.sortWeight < $1.severity.sortWeight }
    }

    private func frequencyInsights() -> [TrainingInsight] {
        let count = lastWeekSessions.count
        let target = profile.daysAvailablePerWeek

        if count == 0 {
            return [TrainingInsight(
                title: "No sessions logged this week",
                detail: "Nothing logged in the last 7 days. If you trained but forgot to log it, add it now so your analysis stays accurate.",
                severity: .notice,
                sfSymbol: "calendar.badge.exclamationmark"
            )]
        }
        if count < max(2, target - 1) {
            return [TrainingInsight(
                title: "Training frequency is a bit low",
                detail: "You logged \(count) session\(count == 1 ? "" : "s") this week against a target of \(target). Most goals respond better to spreading volume across more sessions than cramming it into fewer, longer ones.",
                severity: .warning,
                sfSymbol: "calendar"
            )]
        }
        if count > target + 2 {
            return [TrainingInsight(
                title: "Training frequency is high",
                detail: "You logged \(count) sessions this week, well above your \(target)-day target. That's fine if recovery, sleep, and nutrition are keeping pace — otherwise consider a lighter or rest day soon.",
                severity: .notice,
                sfSymbol: "calendar"
            )]
        }
        return [TrainingInsight(
            title: "Training frequency looks on track",
            detail: "\(count) sessions logged this week, in line with your \(target)-day target.",
            severity: .good,
            sfSymbol: "calendar.badge.checkmark"
        )]
    }

    private func volumeInsights() -> [TrainingInsight] {
        let volumes = weeklyVolumeByMuscle()
        var out: [TrainingInsight] = []

        let neglected = volumes.filter { $0.weeklySets == 0 }
        if !neglected.isEmpty {
            let names = neglected.prefix(4).map { $0.muscle.displayName }.joined(separator: ", ")
            out.append(TrainingInsight(
                title: "Muscle groups getting no direct work",
                detail: "No sets logged this week for: \(names). If this isn't intentional (e.g. a focused split where they're due later this week), consider adding direct work.",
                severity: .notice,
                sfSymbol: "figure.strengthtraining.traditional"
            ))
        }

        let underdosed = volumes.filter { $0.weeklySets > 0 && $0.weeklySets < $0.recommendedRange.lowerBound }
        for m in underdosed.prefix(3) {
            out.append(TrainingInsight(
                title: "\(m.muscle.displayName) volume is low",
                detail: "\(m.weeklySets) working sets this week, below the typical \(m.recommendedRange.lowerBound)–\(m.recommendedRange.upperBound) set/week range for your experience level. A rough guideline, but worth closing the gap gradually.",
                severity: .warning,
                sfSymbol: "arrow.down.circle"
            ))
        }

        let overdosed = volumes.filter { $0.weeklySets > $0.recommendedRange.upperBound }
        for m in overdosed.prefix(3) {
            out.append(TrainingInsight(
                title: "\(m.muscle.displayName) volume is high",
                detail: "\(m.weeklySets) working sets this week, above the typical \(m.recommendedRange.lowerBound)–\(m.recommendedRange.upperBound) set/week range. More isn't always better — extra junk volume can eat into recovery without adding progress.",
                severity: .notice,
                sfSymbol: "arrow.up.circle"
            ))
        }

        if underdosed.isEmpty && overdosed.isEmpty && !volumes.allSatisfy({ $0.weeklySets == 0 }) {
            out.append(TrainingInsight(
                title: "Weekly volume looks well-dosed",
                detail: "Working sets per muscle group are landing in typical ranges for your experience level this week.",
                severity: .good,
                sfSymbol: "checkmark.circle"
            ))
        }
        return out
    }

    private func balanceInsights() -> [TrainingInsight] {
        let volumes = weeklyVolumeByMuscle()
        func sets(_ m: MuscleGroup) -> Int { volumes.first(where: { $0.muscle == m })?.weeklySets ?? 0 }

        let push = sets(.chest) + sets(.shoulders) + sets(.triceps)
        let pull = sets(.back) + sets(.biceps)
        let quadSets = sets(.quads)
        let hamGluteSets = sets(.hamstrings) + sets(.glutes)

        var out: [TrainingInsight] = []

        if push > 0 || pull > 0 {
            let ratio = pull == 0 ? Double(push) : Double(push) / Double(pull)
            if ratio > 1.6 {
                out.append(TrainingInsight(
                    title: "Push/pull imbalance",
                    detail: "Push volume (chest/shoulders/triceps) is noticeably higher than pull volume (back/biceps) this week. Over time this pattern is linked to rounded-shoulder posture and shoulder strain — worth adding rows or pulldowns.",
                    severity: .warning,
                    sfSymbol: "arrow.left.arrow.right"
                ))
            }
        }

        if quadSets > 0 || hamGluteSets > 0 {
            let ratio = hamGluteSets == 0 ? Double(quadSets) : Double(quadSets) / Double(hamGluteSets)
            if ratio > 2.0 {
                out.append(TrainingInsight(
                    title: "Quad-dominant lower body training",
                    detail: "Quad volume is much higher than hamstring/glute volume this week. Balancing these helps knee health and overall lower-body strength — consider Romanian deadlifts, leg curls, or hip thrusts.",
                    severity: .notice,
                    sfSymbol: "figure.walk"
                ))
            }
        }

        return out
    }

    private func repRangeInsights() -> [TrainingInsight] {
        let ideal = profile.goal.idealRepRange
        var outsideCount = 0
        var totalCount = 0

        for session in lastWeekSessions {
            for set in session.sets where !set.isWarmup {
                totalCount += 1
                if !ideal.contains(set.reps) { outsideCount += 1 }
            }
        }

        guard totalCount >= 6 else { return [] } // not enough data yet

        let fraction = Double(outsideCount) / Double(totalCount)
        if fraction > 0.5 {
            return [TrainingInsight(
                title: "Rep ranges don't match your goal",
                detail: "Over half your recent sets fall outside the \(ideal.lowerBound)-\(ideal.upperBound) rep range that best serves a \(profile.goal.displayName.lowercased()) goal. Not a hard rule, but drifting this far off suggests your program and stated goal may be out of sync.",
                severity: .notice,
                sfSymbol: "target"
            )]
        }
        return []
    }

    private func recoveryInsights() -> [TrainingInsight] {
        // Look for the same primary muscle trained on back-to-back days with no gap.
        let sorted = last28DaySessions.sorted { $0.date < $1.date }
        var lastTrainedDate: [MuscleGroup: Date] = [:]
        var backToBackFlags: [MuscleGroup: Int] = [:]

        let calendar = Calendar.current
        for session in sorted {
            for muscle in session.muscleGroupsTouched where muscle != .fullBody {
                if let last = lastTrainedDate[muscle] {
                    let gap = calendar.dateComponents([.hour], from: last, to: session.date).hour ?? 999
                    if gap < 24 {
                        backToBackFlags[muscle, default: 0] += 1
                    }
                }
                lastTrainedDate[muscle] = session.date
            }
        }

        let flagged = backToBackFlags.filter { $0.value >= 2 }
        guard !flagged.isEmpty else { return [] }
        let names = flagged.keys.map { $0.displayName }.joined(separator: ", ")
        return [TrainingInsight(
            title: "Limited recovery between sessions",
            detail: "\(names) have been trained on consecutive days multiple times in the last 4 weeks. Most muscle groups recover and grow best with roughly 48 hours before the next hard session on the same group.",
            severity: .notice,
            sfSymbol: "bed.double"
        )]
    }

    private func progressionInsights() -> [TrainingInsight] {
        // For each exercise trained 3+ times in the last 28 days, check if
        // estimated 1RM trend is flat/declining — a classic plateau signal.
        var byExercise: [String: [ExerciseProgressPoint]] = [:]
        for session in last28DaySessions.sorted(by: { $0.date < $1.date }) {
            for set in session.sets where !set.isWarmup {
                guard let ex = set.exercise else { continue }
                byExercise[ex.id, default: []].append(ExerciseProgressPoint(date: session.date, estimated1RM: set.estimated1RM))
            }
        }

        var plateauCount = 0
        var improvingCount = 0
        for (_, points) in byExercise where points.count >= 3 {
            let first = points.prefix(points.count / 2).map { $0.estimated1RM }.max() ?? 0
            let second = points.suffix(points.count / 2).map { $0.estimated1RM }.max() ?? 0
            if second <= first * 1.01 {
                plateauCount += 1
            } else {
                improvingCount += 1
            }
        }

        if plateauCount >= 2 && plateauCount >= improvingCount {
            return [TrainingInsight(
                title: "Several lifts look plateaued",
                detail: "Estimated strength hasn't meaningfully increased on \(plateauCount) regularly-trained exercise\(plateauCount == 1 ? "" : "s") over the last month. Consider a deload, a rep/weight change, or checking sleep and nutrition.",
                severity: .notice,
                sfSymbol: "chart.line.flattrend.xyaxis"
            )]
        }
        if improvingCount >= 2 {
            return [TrainingInsight(
                title: "Progressive overload is happening",
                detail: "Estimated strength trended upward on \(improvingCount) regularly-trained exercises over the last month. Keep it up.",
                severity: .good,
                sfSymbol: "chart.line.uptrend.xyaxis"
            )]
        }
        return []
    }
}
