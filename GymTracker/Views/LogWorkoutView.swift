import SwiftUI
import SwiftData

struct LogWorkoutView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    @State private var activeSession: WorkoutSession?
    @State private var showExercisePicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                if let activeSession {
                    SessionEditorView(session: activeSession, onFinish: { self.activeSession = nil })
                } else {
                    startScreen
                }
            }
            .navigationTitle("Log Workout")
        }
    }

    private var startScreen: some View {
        ScrollView {
            VStack(spacing: 20) {
                Button(action: startNewSession) {
                    VStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 40))
                        Text("Start New Session")
                            .font(.headline)
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                    .background(AppTheme.heroGradient)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner))
                }
                .padding(.top, 8)

                if !sessions.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Past Sessions").font(.headline).foregroundStyle(AppTheme.textPrimary)
                        ForEach(sessions) { session in
                            Button {
                                activeSession = session
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(session.name).font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.textPrimary)
                                        Text(session.date.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(AppTheme.textTertiary)
                                }
                                .cardStyle(padding: 14)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(20)
        }
    }

    private func startNewSession() {
        let session = WorkoutSession(date: .now, name: defaultSessionName())
        context.insert(session)
        try? context.save()
        activeSession = session
    }

    private func defaultSessionName() -> String {
        let hour = Calendar.current.component(.hour, from: .now)
        return hour < 12 ? "Morning Session" : (hour < 18 ? "Afternoon Session" : "Evening Session")
    }
}

/// Editing surface for one session: rename, add exercises, log sets, add notes.
struct SessionEditorView: View {
    @Bindable var session: WorkoutSession
    let onFinish: () -> Void

    @Environment(\.modelContext) private var context
    @State private var showExercisePicker = false

    private var groupedSets: [(Exercise, [SetEntry])] {
        var order: [String] = []
        var groups: [String: [SetEntry]] = [:]
        for set in session.sets.sorted(by: { $0.order < $1.order }) {
            guard let ex = set.exercise else { continue }
            if groups[ex.id] == nil { order.append(ex.id) }
            groups[ex.id, default: []].append(set)
        }
        return order.compactMap { id in
            guard let sets = groups[id], let ex = sets.first?.exercise else { return nil }
            return (ex, sets)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                TextField("Session name", text: $session.name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .textFieldStyle(.plain)

                Text(session.date.formatted(date: .complete, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)

                if groupedSets.isEmpty {
                    Text("No exercises added yet.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .cardStyle()
                } else {
                    ForEach(groupedSets, id: \.0.id) { exercise, sets in
                        ExerciseSetGroup(exercise: exercise, sets: sets, session: session)
                    }
                }

                Button {
                    showExercisePicker = true
                } label: {
                    Label("Add Exercise", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.smallCorner))
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Notes").font(.caption.weight(.semibold)).foregroundStyle(AppTheme.textSecondary).textCase(.uppercase)
                    TextField("How did it feel?", text: $session.notes, axis: .vertical)
                        .lineLimit(3...6)
                        .padding(12)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.smallCorner))
                        .foregroundStyle(AppTheme.textPrimary)
                }

                Button(action: finish) {
                    Text("Finish Session")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.heroGradient)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner))
                }
                .padding(.top, 6)
            }
            .padding(20)
        }
        .sheet(isPresented: $showExercisePicker) {
            ExercisePickerSheet { exercise in
                addSet(for: exercise)
            }
        }
    }

    private func addSet(for exercise: Exercise) {
        let nextOrder = (session.sets.map { $0.order }.max() ?? -1) + 1
        let set = SetEntry(reps: 10, weightKG: 20, order: nextOrder, exercise: exercise)
        set.session = session
        session.sets.append(set)
        context.insert(set)
        try? context.save()
    }

    private func finish() {
        try? context.save()
        onFinish()
    }
}

/// One exercise's block of sets within the session editor, with inline steppers.
struct ExerciseSetGroup: View {
    let exercise: Exercise
    let sets: [SetEntry]
    let session: WorkoutSession

    @Environment(\.modelContext) private var context

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(exercise.name).font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.textPrimary)
                Spacer()
                TagView(text: exercise.primaryMuscle.displayName, color: AppTheme.accentSecondary)
            }

            ForEach(sets) { set in
                SetRowEditor(set: set, onDelete: { delete(set) })
            }

            Button {
                addSet()
            } label: {
                Label("Add Set", systemImage: "plus.circle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
            }
        }
        .cardStyle()
    }

    private func addSet() {
        let last = sets.last
        let nextOrder = (session.sets.map { $0.order }.max() ?? -1) + 1
        let set = SetEntry(reps: last?.reps ?? 10, weightKG: last?.weightKG ?? 20, order: nextOrder, exercise: exercise)
        set.session = session
        session.sets.append(set)
        context.insert(set)
        try? context.save()
    }

    private func delete(_ set: SetEntry) {
        session.sets.removeAll { $0.id == set.id }
        context.delete(set)
        try? context.save()
    }
}

struct SetRowEditor: View {
    @Bindable var set: SetEntry
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: $set.isWarmup)
                .labelsHidden()
                .toggleStyle(.button)
                .tint(AppTheme.warning)
                .overlay(
                    Image(systemName: "flame")
                        .font(.caption2)
                        .foregroundStyle(set.isWarmup ? .black : AppTheme.textTertiary)
                        .allowsHitTesting(false)
                )

            stepperField(label: "kg", value: Binding(
                get: { set.weightKG },
                set: { set.weightKG = max(0, $0) }
            ), step: 2.5, format: "%.1f")

            stepperField(label: "reps", value: Binding(
                get: { Double(set.reps) },
                set: { set.reps = max(0, Int($0)) }
            ), step: 1, format: "%.0f")

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(AppTheme.danger)
            }
        }
    }

    private func stepperField(label: String, value: Binding<Double>, step: Double, format: String) -> some View {
        HStack(spacing: 6) {
            Button { value.wrappedValue -= step } label: {
                Image(systemName: "minus.circle.fill").foregroundStyle(AppTheme.textTertiary)
            }
            VStack(spacing: 0) {
                Text(String(format: format, value.wrappedValue))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(minWidth: 40)
                Text(label).font(.caption2).foregroundStyle(AppTheme.textTertiary)
            }
            Button { value.wrappedValue += step } label: {
                Image(systemName: "plus.circle.fill").foregroundStyle(AppTheme.accent)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LogWorkoutView()
        .modelContainer(for: [Exercise.self, WorkoutSession.self, SetEntry.self, UserProfile.self], inMemory: true)
}
