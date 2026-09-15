import SwiftUI
import SwiftData

struct ExerciseLibraryView: View {
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Environment(\.modelContext) private var context

    @State private var searchText = ""
    @State private var selectedMuscle: MuscleGroup?
    @State private var showAddCustom = false
    @State private var remoteResults: [RemoteExercise] = []
    @State private var isSearchingRemote = false

    private var filtered: [Exercise] {
        exercises.filter { ex in
            (selectedMuscle == nil || ex.primaryMuscle == selectedMuscle) &&
            (searchText.isEmpty || ex.name.localizedCaseInsensitiveContains(searchText))
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        muscleFilterRow

                        if !remoteResults.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("From wger.de").font(.caption.weight(.semibold)).foregroundStyle(AppTheme.textSecondary).textCase(.uppercase)
                                ForEach(remoteResults) { remote in
                                    Button { importRemote(remote) } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(remote.name).font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.textPrimary)
                                                Text(remote.primaryMuscle.displayName).font(.caption).foregroundStyle(AppTheme.textSecondary)
                                            }
                                            Spacer()
                                            Image(systemName: "plus.circle").foregroundStyle(AppTheme.accent)
                                        }
                                        .cardStyle(padding: 12)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        ForEach(filtered) { exercise in
                            NavigationLink {
                                ExerciseDetailView(exercise: exercise)
                            } label: {
                                ExerciseRow(exercise: exercise)
                            }
                            .buttonStyle(.plain)
                        }

                        if filtered.isEmpty && remoteResults.isEmpty {
                            Text(isSearchingRemote ? "Searching..." : "No exercises found. Try a different search, or add a custom one.")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                                .cardStyle()
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Exercises")
            .searchable(text: $searchText, prompt: "Search exercises")
            .onChange(of: searchText) { _, newValue in searchRemote(newValue) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddCustom = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddCustom) {
                AddCustomExerciseView()
            }
        }
    }

    private var muscleFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: "All", isSelected: selectedMuscle == nil) { selectedMuscle = nil }
                ForEach(MuscleGroup.allCases) { muscle in
                    filterChip(title: muscle.displayName, isSelected: selectedMuscle == muscle) { selectedMuscle = muscle }
                }
            }
        }
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(isSelected ? .black : AppTheme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? AppTheme.accent : AppTheme.surface)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func searchRemote(_ term: String) {
        guard term.count >= 3 else { remoteResults = []; return }
        isSearchingRemote = true
        Task {
            let results = (try? await ExerciseAPIService.shared.searchExercises(term: term)) ?? []
            let existingIDs = Set(exercises.map { $0.id })
            await MainActor.run {
                remoteResults = results.filter { !existingIDs.contains($0.id) }
                isSearchingRemote = false
            }
        }
    }

    private func importRemote(_ remote: RemoteExercise) {
        let ex = Exercise(
            id: remote.id,
            name: remote.name,
            exerciseDescription: remote.description,
            primaryMuscle: remote.primaryMuscle,
            secondaryMuscles: remote.secondaryMuscles,
            category: remote.category,
            equipment: remote.equipment,
            imageURLString: remote.imageURLString,
            isCustom: false,
            source: "wger"
        )
        context.insert(ex)
        try? context.save()
        remoteResults.removeAll { $0.id == remote.id }
    }
}

struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(AppTheme.surfaceElevated)
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(AppTheme.textTertiary)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name).font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.textPrimary)
                HStack(spacing: 6) {
                    TagView(text: exercise.primaryMuscle.displayName, color: AppTheme.accentSecondary)
                    if exercise.isCustom {
                        TagView(text: "Custom", color: AppTheme.warning)
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(AppTheme.textTertiary)
        }
        .cardStyle(padding: 12)
    }
}

/// Sheet used from the Log Workout flow: pick an existing exercise to add sets for.
struct ExercisePickerSheet: View {
    let onPick: (Exercise) -> Void
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filtered: [Exercise] {
        searchText.isEmpty ? exercises : exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(filtered) { exercise in
                            Button {
                                onPick(exercise)
                                dismiss()
                            } label: {
                                ExerciseRow(exercise: exercise)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
            }
            .searchable(text: $searchText, prompt: "Search")
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ExerciseLibraryView()
        .modelContainer(for: [Exercise.self, WorkoutSession.self, SetEntry.self, UserProfile.self], inMemory: true)
}
