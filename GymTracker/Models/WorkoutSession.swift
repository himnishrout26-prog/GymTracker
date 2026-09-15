import Foundation
import SwiftData

/// A single day's gym session. Contains an ordered list of SetEntry rows,
/// each pointing at an Exercise. This is the core unit the analyzer reasons
/// about (frequency, duration, volume-per-session).
@Model
final class WorkoutSession {
    var date: Date
    var name: String
    var notes: String
    var bodyWeightKG: Double?
    var durationMinutes: Int?
    var perceivedEffort: Int? // RPE-style 1-10, session-level, optional

    @Relationship(deleteRule: .cascade, inverse: \SetEntry.session)
    var sets: [SetEntry] = []

    init(
        date: Date = .now,
        name: String = "Workout",
        notes: String = "",
        bodyWeightKG: Double? = nil,
        durationMinutes: Int? = nil,
        perceivedEffort: Int? = nil
    ) {
        self.date = date
        self.name = name
        self.notes = notes
        self.bodyWeightKG = bodyWeightKG
        self.durationMinutes = durationMinutes
        self.perceivedEffort = perceivedEffort
    }

    /// Total working volume for the session (sum of weight * reps across all sets).
    var totalVolume: Double {
        sets.reduce(0) { $0 + $1.volume }
    }

    /// Distinct muscle groups hit this session (primary muscle of each exercise logged).
    var muscleGroupsTouched: Set<MuscleGroup> {
        Set(sets.compactMap { $0.exercise?.primaryMuscle })
    }
}

/// One working set: an exercise, weight, reps, and how hard it felt.
@Model
final class SetEntry {
    var reps: Int
    var weightKG: Double
    var rpe: Double? // Rate of Perceived Exertion, 1-10 (optional but used heavily by the analyzer)
    var isWarmup: Bool
    var order: Int
    var timestamp: Date

    var exercise: Exercise?
    var session: WorkoutSession?

    init(
        reps: Int,
        weightKG: Double,
        rpe: Double? = nil,
        isWarmup: Bool = false,
        order: Int = 0,
        timestamp: Date = .now,
        exercise: Exercise? = nil
    ) {
        self.reps = reps
        self.weightKG = weightKG
        self.rpe = rpe
        self.isWarmup = isWarmup
        self.order = order
        self.timestamp = timestamp
        self.exercise = exercise
    }

    /// Working volume for just this set. Warmups are excluded from volume math
    /// in the analyzer (see WorkoutAnalyzer) but the raw value is still here.
    var volume: Double { weightKG * Double(reps) }

    /// Estimated 1-rep max via the Epley formula, used for progression trend tracking.
    var estimated1RM: Double {
        guard reps > 0 else { return weightKG }
        return weightKG * (1 + Double(reps) / 30.0)
    }
}
