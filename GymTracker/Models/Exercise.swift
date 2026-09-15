import Foundation
import SwiftData

/// Broad muscle groups we use for volume/balance analysis.
/// Kept deliberately simple (vs wger's ~15 granular muscles) so the
/// analyzer's weekly-volume math stays meaningful.
enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest, back, shoulders, biceps, triceps, quads, hamstrings, glutes, calves, core, forearms, fullBody

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fullBody: return "Full Body"
        default: return rawValue.capitalized
        }
    }
}

enum ExerciseCategory: String, Codable, CaseIterable, Identifiable {
    case strength, cardio, mobility, plyometric

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
}

/// Persisted, locally-cached exercise. Populated from the wger.de API on
/// first launch (and on demand from the library search), then stored so the
/// app works offline afterwards. Users can also add fully custom exercises.
@Model
final class Exercise {
    @Attribute(.unique) var id: String
    var name: String
    var exerciseDescription: String
    var primaryMuscleRaw: String
    var secondaryMusclesRaw: [String]
    var categoryRaw: String
    var equipment: [String]
    var imageURLString: String?
    var isCustom: Bool
    var source: String // "wger" or "custom"

    init(
        id: String = UUID().uuidString,
        name: String,
        exerciseDescription: String = "",
        primaryMuscle: MuscleGroup,
        secondaryMuscles: [MuscleGroup] = [],
        category: ExerciseCategory = .strength,
        equipment: [String] = [],
        imageURLString: String? = nil,
        isCustom: Bool = false,
        source: String = "wger"
    ) {
        self.id = id
        self.name = name
        self.exerciseDescription = exerciseDescription
        self.primaryMuscleRaw = primaryMuscle.rawValue
        self.secondaryMusclesRaw = secondaryMuscles.map { $0.rawValue }
        self.categoryRaw = category.rawValue
        self.equipment = equipment
        self.imageURLString = imageURLString
        self.isCustom = isCustom
        self.source = source
    }

    var primaryMuscle: MuscleGroup {
        get { MuscleGroup(rawValue: primaryMuscleRaw) ?? .fullBody }
        set { primaryMuscleRaw = newValue.rawValue }
    }

    var secondaryMuscles: [MuscleGroup] {
        get { secondaryMusclesRaw.compactMap { MuscleGroup(rawValue: $0) } }
        set { secondaryMusclesRaw = newValue.map { $0.rawValue } }
    }

    var category: ExerciseCategory {
        get { ExerciseCategory(rawValue: categoryRaw) ?? .strength }
        set { categoryRaw = newValue.rawValue }
    }

    var imageURL: URL? {
        guard let imageURLString else { return nil }
        return URL(string: imageURLString)
    }
}
