import SwiftUI
import SwiftData

struct AddCustomExerciseView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var primaryMuscle: MuscleGroup = .fullBody
    @State private var category: ExerciseCategory = .strength
    @State private var description = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        labeledField("Name") {
                            TextField("e.g. Cable Chest Fly", text: $name)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(AppTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.smallCorner))
                                .foregroundStyle(AppTheme.textPrimary)
                        }

                        labeledField("Primary Muscle") {
                            Picker("", selection: $primaryMuscle) {
                                ForEach(MuscleGroup.allCases) { Text($0.displayName).tag($0) }
                            }
                            .pickerStyle(.menu)
                            .tint(AppTheme.accent)
                        }

                        labeledField("Category") {
                            Picker("", selection: $category) {
                                ForEach(ExerciseCategory.allCases) { Text($0.displayName).tag($0) }
                            }
                            .pickerStyle(.segmented)
                        }

                        labeledField("Notes (optional)") {
                            TextField("Cues, setup, etc.", text: $description, axis: .vertical)
                                .lineLimit(2...5)
                                .padding(12)
                                .background(AppTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.smallCorner))
                                .foregroundStyle(AppTheme.textPrimary)
                        }

                        Button(action: save) {
                            Text("Save Exercise")
                                .font(.headline)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(name.isEmpty ? AnyShapeStyle(AppTheme.textTertiary) : AnyShapeStyle(AppTheme.heroGradient))
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner))
                        }
                        .disabled(name.isEmpty)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Custom Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func labeledField<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(AppTheme.textSecondary).textCase(.uppercase)
            content()
        }
    }

    private func save() {
        let ex = Exercise(
            name: name,
            exerciseDescription: description,
            primaryMuscle: primaryMuscle,
            category: category,
            isCustom: true,
            source: "custom"
        )
        context.insert(ex)
        try? context.save()
        dismiss()
    }
}
