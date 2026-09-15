import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var context

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                if let profile {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 22) {
                            VStack(spacing: 10) {
                                ZStack {
                                    Circle().fill(AppTheme.heroGradient).frame(width: 74, height: 74)
                                    Text(initials(for: profile.name))
                                        .font(.title2.bold())
                                        .foregroundStyle(.black)
                                }
                                TextField("Name", text: Binding(get: { profile.name }, set: { profile.name = $0; save() }))
                                    .font(.title3.weight(.semibold))
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(AppTheme.textPrimary)
                            }
                            .frame(maxWidth: .infinity)

                            section("Training Goal") {
                                FlowChoices(items: TrainingGoal.allCases, selection: Binding(get: { profile.goal }, set: { profile.goal = $0; save() })) { $0.displayName }
                            }

                            section("Experience Level") {
                                FlowChoices(items: ExperienceLevel.allCases, selection: Binding(get: { profile.experience }, set: { profile.experience = $0; save() })) { $0.displayName }
                            }

                            section("Days Available Per Week: \(profile.daysAvailablePerWeek)") {
                                Slider(value: Binding(get: { Double(profile.daysAvailablePerWeek) }, set: { profile.daysAvailablePerWeek = Int($0); save() }), in: 1...7, step: 1)
                                    .tint(AppTheme.accent)
                            }

                            section("Body Weight (kg)") {
                                TextField("Optional", value: Binding(get: { profile.bodyWeightKG }, set: { profile.bodyWeightKG = $0; save() }), format: .number)
                                    .keyboardType(.decimalPad)
                                    .padding(12)
                                    .background(AppTheme.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.smallCorner))
                                    .foregroundStyle(AppTheme.textPrimary)
                            }

                            section("Injuries / Limitations") {
                                TextField("e.g. lower back sensitivity", text: Binding(get: { profile.injuriesOrLimitations }, set: { profile.injuriesOrLimitations = $0; save() }), axis: .vertical)
                                    .lineLimit(2...5)
                                    .padding(12)
                                    .background(AppTheme.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.smallCorner))
                                    .foregroundStyle(AppTheme.textPrimary)
                                Text("Noted for your reference. The analyzer doesn't yet screen individual exercises against this — always use your judgment or a professional's.")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.textTertiary)
                            }

                            VStack(spacing: 4) {
                                Text("GymTracker")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppTheme.textSecondary)
                                Text("Made by Himnish")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.textTertiary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 12)
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(AppTheme.textSecondary).textCase(.uppercase)
            content()
        }
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return String(letters).uppercased().isEmpty ? "Y" : String(letters).uppercased()
    }

    private func save() {
        try? context.save()
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [Exercise.self, WorkoutSession.self, SetEntry.self, UserProfile.self], inMemory: true)
}
