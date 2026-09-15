import Foundation

/// Talks to the free, public wger.de exercise database
/// (https://wger.de/en/software/api — no API key required for read access).
///
/// NOTE: wger's public API has shifted shape across versions (exercise vs.
/// exerciseinfo vs. exercisebaseinfo endpoints). This service decodes
/// defensively — every field is optional-safe — and falls back to the
/// bundled starter exercises (see ExerciseSeedData) if a request fails, so
/// the app is never left with an empty library, even fully offline.
/// If wger changes a field name on their end, only this file needs edits.
actor ExerciseAPIService {
    static let shared = ExerciseAPIService()

    private let baseURL = "https://wger.de/api/v2"
    private let session = URLSession.shared

    /// Fetches a page of exercises in English with basic muscle/category/image info.
    func fetchExercises(limit: Int = 50, offset: Int = 0) async throws -> [RemoteExercise] {
        var components = URLComponents(string: "\(baseURL)/exerciseinfo/")!
        components.queryItems = [
            URLQueryItem(name: "language", value: "2"), // 2 = English
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "format", value: "json")
        ]
        let (data, response) = try await session.data(from: components.url!)
        try Self.validate(response)
        let page = try JSONDecoder().decode(WgerPage<WgerExerciseInfo>.self, from: data)
        return page.results.compactMap { $0.toRemoteExercise() }
    }

    /// Free-text search, e.g. "bench press".
    func searchExercises(term: String) async throws -> [RemoteExercise] {
        guard !term.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        var components = URLComponents(string: "\(baseURL)/exercise/search/")!
        components.queryItems = [
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "language", value: "english"),
            URLQueryItem(name: "format", value: "json")
        ]
        let (data, response) = try await session.data(from: components.url!)
        try Self.validate(response)
        let page = try JSONDecoder().decode(WgerSearchResponse.self, from: data)
        return page.suggestions.compactMap { $0.data.toRemoteExercise(fallbackName: $0.value) }
    }

    private static func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw ExerciseAPIError.badResponse
        }
    }
}

enum ExerciseAPIError: LocalizedError {
    case badResponse
    var errorDescription: String? { "Couldn't reach the exercise database. Showing what's saved on your device instead." }
}

/// A cleaned-up, app-friendly exercise, decoded from whichever wger shape came back.
struct RemoteExercise: Identifiable {
    let id: String
    let name: String
    let description: String
    let primaryMuscle: MuscleGroup
    let secondaryMuscles: [MuscleGroup]
    let category: ExerciseCategory
    let equipment: [String]
    let imageURLString: String?
}

// MARK: - Raw wger response shapes (defensive decoding)

private struct WgerPage<T: Decodable>: Decodable {
    let count: Int?
    let results: [T]
}

private struct WgerExerciseInfo: Decodable {
    let id: Int
    let category: WgerCategory?
    let muscles: [WgerMuscle]?
    let musclesSecondary: [WgerMuscle]?
    let equipment: [WgerEquipment]?
    let images: [WgerImage]?
    let translations: [WgerTranslation]?

    enum CodingKeys: String, CodingKey {
        case id, category, muscles
        case musclesSecondary = "muscles_secondary"
        case equipment, images, translations
    }

    func toRemoteExercise() -> RemoteExercise? {
        // English translation carries the human-readable name/description.
        let translation = translations?.first(where: { $0.language == 2 }) ?? translations?.first
        guard let name = translation?.name, !name.isEmpty else { return nil }

        return RemoteExercise(
            id: "wger-\(id)",
            name: name,
            description: (translation?.description ?? "").strippingHTML(),
            primaryMuscle: muscles?.first?.mapped ?? .fullBody,
            secondaryMuscles: musclesSecondary?.map { $0.mapped } ?? [],
            category: category?.mapped ?? .strength,
            equipment: equipment?.map { $0.name } ?? [],
            imageURLString: images?.first(where: { $0.isMain == true })?.image ?? images?.first?.image
        )
    }
}

private struct WgerTranslation: Decodable {
    let name: String?
    let description: String?
    let language: Int?
}

private struct WgerCategory: Decodable {
    let name: String?

    var mapped: ExerciseCategory {
        switch name?.lowercased() {
        case "cardio": return .cardio
        case "stretching": return .mobility
        default: return .strength
        }
    }
}

private struct WgerMuscle: Decodable {
    let name: String?
    let nameEn: String?

    enum CodingKeys: String, CodingKey {
        case name
        case nameEn = "name_en"
    }

    var mapped: MuscleGroup {
        let key = (nameEn ?? name ?? "").lowercased()
        if key.contains("chest") || key.contains("pectoral") { return .chest }
        if key.contains("lat") || key.contains("trapezius") || key.contains("back") { return .back }
        if key.contains("delt") || key.contains("shoulder") { return .shoulders }
        if key.contains("bicep") { return .biceps }
        if key.contains("tricep") { return .triceps }
        if key.contains("quad") { return .quads }
        if key.contains("hamstring") { return .hamstrings }
        if key.contains("glute") { return .glutes }
        if key.contains("calv") || key.contains("calf") { return .calves }
        if key.contains("abdom") || key.contains("core") || key.contains("oblique") { return .core }
        if key.contains("forearm") || key.contains("brachioradialis") { return .forearms }
        return .fullBody
    }
}

private struct WgerEquipment: Decodable {
    let name: String
}

private struct WgerImage: Decodable {
    let image: String?
    let isMain: Bool?

    enum CodingKeys: String, CodingKey {
        case image
        case isMain = "is_main"
    }
}

private struct WgerSearchResponse: Decodable {
    let suggestions: [WgerSuggestion]
}

private struct WgerSuggestion: Decodable {
    let value: String
    let data: WgerSuggestionData
}

private struct WgerSuggestionData: Decodable {
    let baseId: Int?
    let category: String?
    let image: String?

    enum CodingKeys: String, CodingKey {
        case baseId = "base_id"
        case category, image
    }

    func toRemoteExercise(fallbackName: String) -> RemoteExercise? {
        guard let baseId else { return nil }
        return RemoteExercise(
            id: "wger-\(baseId)",
            name: fallbackName.strippingHTML(),
            description: "",
            primaryMuscle: .fullBody,
            secondaryMuscles: [],
            category: .strength,
            equipment: [],
            imageURLString: image
        )
    }
}

private extension String {
    /// wger descriptions come back with HTML like <p>...</p>; strip it for display.
    func strippingHTML() -> String {
        replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
