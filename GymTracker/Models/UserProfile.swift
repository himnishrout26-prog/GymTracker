import Foundation
import SwiftData

enum TrainingGoal: String, Codable, CaseIterable, Identifiable {
    case strength, hypertrophy, endurance, generalFitness, fatLoss

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .strength: return "Strength"
        case .hypertrophy: return "Muscle Growth"
        case .endurance: return "Endurance"
        case .generalFitness: return "General Fitness"
        case .fatLoss: return "Fat Loss"
        }
    }

    /// Target working-rep range this goal is best served by. Used by the
    /// analyzer to flag sets that are way outside the ideal zone.
    var idealRepRange: ClosedRange<Int> {
        switch self {
        case .strength: return 1...6
        case .hypertrophy: return 6...12
        case .endurance: return 12...20
        case .generalFitness: return 6...15
        case .fatLoss: return 8...15
        }
    }
}

enum ExperienceLevel: String, Codable, CaseIterable, Identifiable {
    case beginner, intermediate, advanced

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }

    /// Recommended weekly hard sets per muscle group, low-high, per
    /// widely-cited hypertrophy/strength training volume landmarks
    /// (roughly aligned with Israetel/Helms-style volume landmarks).
    /// This is a heuristic, not medical advice.
    var weeklySetLandmarks: (min: Int, max: Int) {
        switch self {
        case .beginner: return (8, 12)
        case .intermediate: return (10, 18)
        case .advanced: return (12, 22)
        }
    }
}

@Model
final class UserProfile {
    var name: String
    var goal: TrainingGoal
    var experience: ExperienceLevel
    var daysAvailablePerWeek: Int
    var heightCM: Double?
    var bodyWeightKG: Double?
    var birthYear: Int?
    var injuriesOrLimitations: String

    init(
        name: String = "You",
        goal: TrainingGoal = .generalFitness,
        experience: ExperienceLevel = .beginner,
        daysAvailablePerWeek: Int = 3,
        heightCM: Double? = nil,
        bodyWeightKG: Double? = nil,
        birthYear: Int? = nil,
        injuriesOrLimitations: String = ""
    ) {
        self.name = name
        self.goal = goal
        self.experience = experience
        self.daysAvailablePerWeek = daysAvailablePerWeek
        self.heightCM = heightCM
        self.bodyWeightKG = bodyWeightKG
        self.birthYear = birthYear
        self.injuriesOrLimitations = injuriesOrLimitations
    }
}
