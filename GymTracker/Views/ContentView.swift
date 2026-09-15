import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]
    @Query private var exercises: [Exercise]

    @State private var showOnboarding = false
    @State private var didAttemptSeed = false
    @State private var showSplash = true

    var body: some View {
        Group {
            if showSplash {
                SplashView()
                    .task {
                        try? await Task.sleep(nanoseconds: 1_100_000_000)
                        withAnimation(.easeOut(duration: 0.25)) { showSplash = false }
                    }
            } else if profiles.isEmpty && !showOnboarding {
                // First launch: create a default profile immediately so every
                // other screen has one to read, then show onboarding to refine it.
                Color.clear.onAppear {
                    context.insert(UserProfile())
                    try? context.save()
                    showOnboarding = true
                }
            } else {
                TabView {
                    DashboardView()
                        .tabItem { Label("Dashboard", systemImage: "square.grid.2x2.fill") }

                    LogWorkoutView()
                        .tabItem { Label("Log", systemImage: "plus.circle.fill") }

                    AnalysisView()
                        .tabItem { Label("Analysis", systemImage: "chart.bar.fill") }

                    ExerciseLibraryView()
                        .tabItem { Label("Exercises", systemImage: "figure.strengthtraining.traditional") }

                    ProfileView()
                        .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                }
                .tint(AppTheme.accent)
                .task { seedExerciseLibraryIfNeeded() }
                .sheet(isPresented: $showOnboarding) {
                    OnboardingView(isPresented: $showOnboarding)
                }
            }
        }
    }

    /// Populates the local exercise library once: bundled seed data first
    /// (instant, offline), then tries to enrich/extend it from wger.de.
    private func seedExerciseLibraryIfNeeded() {
        guard !didAttemptSeed else { return }
        didAttemptSeed = true

        if exercises.isEmpty {
            for ex in ExerciseSeedData.makeSeedExercises() {
                context.insert(ex)
            }
            try? context.save()
        }

        Task {
            do {
                let remote = try await ExerciseAPIService.shared.fetchExercises(limit: 60)
                await MainActor.run {
                    let existingIDs = Set(exercises.map { $0.id })
                    for r in remote where !existingIDs.contains(r.id) {
                        let ex = Exercise(
                            id: r.id,
                            name: r.name,
                            exerciseDescription: r.description,
                            primaryMuscle: r.primaryMuscle,
                            secondaryMuscles: r.secondaryMuscles,
                            category: r.category,
                            equipment: r.equipment,
                            imageURLString: r.imageURLString,
                            isCustom: false,
                            source: "wger"
                        )
                        context.insert(ex)
                    }
                    try? context.save()
                }
            } catch {
                // Silent fallback — bundled seed data already covers the basics.
                print("Exercise sync skipped: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Exercise.self, WorkoutSession.self, SetEntry.self, UserProfile.self], inMemory: true)
}
