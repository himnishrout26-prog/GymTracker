import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]

    @State private var name = ""
    @State private var goal: TrainingGoal = .generalFitness
    @State private var experience: ExperienceLevel = .beginner
    @State private var daysPerWeek = 3

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Welcome 👋")
                                .font(.largeTitle.bold())
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("A few quick questions so your analysis is personalized, not generic.")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                            Text("GymTracker — made by Himnish")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(AppTheme.accent)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("What should we call you?").sectionLabel()
                            TextField("Name", text: $name)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(AppTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.smallCorner))
                                .foregroundStyle(AppTheme.textPrimary)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Main goal").sectionLabel()
                            FlowChoices(items: TrainingGoal.allCases, selection: $goal) { $0.displayName }
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Experience level").sectionLabel()
                            FlowChoices(items: ExperienceLevel.allCases, selection: $experience) { $0.displayName }
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Days per week you can train: \(daysPerWeek)").sectionLabel()
                            Slider(value: Binding(get: { Double(daysPerWeek) }, set: { daysPerWeek = Int($0) }), in: 1...7, step: 1)
                                .tint(AppTheme.accent)
                        }

                        Button(action: finish) {
                            Text("Start Training")
                                .font(.headline)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(AppTheme.heroGradient)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner))
                        }
                        .padding(.top, 8)
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    private func finish() {
        if let profile = profiles.first {
            profile.name = name.isEmpty ? "You" : name
            profile.goal = goal
            profile.experience = experience
            profile.daysAvailablePerWeek = daysPerWeek
        }
        try? context.save()
        isPresented = false
    }
}

private extension Text {
    func sectionLabel() -> some View {
        self.font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.textSecondary)
            .textCase(.uppercase)
    }
}

/// Wrapping chip selector used for single-choice enum-style pickers.
struct FlowChoices<Item: Identifiable & Hashable>: View {
    let items: [Item]
    @Binding var selection: Item
    let label: (Item) -> String

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(items) { item in
                let isSelected = item == selection
                Button {
                    selection = item
                } label: {
                    Text(label(item))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(isSelected ? .black : AppTheme.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(isSelected ? AppTheme.accent : AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.smallCorner))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
