import Foundation

/// A small, hand-picked set of common exercises bundled with the app so the
/// library and logging flow work immediately — before the first successful
/// wger.de sync, or any time the device is offline.
enum ExerciseSeedData {
    static func makeSeedExercises() -> [Exercise] {
        [
            Exercise(id: "seed-bench-press", name: "Barbell Bench Press", exerciseDescription: "Flat barbell press for chest, shoulders, and triceps.", primaryMuscle: .chest, secondaryMuscles: [.triceps, .shoulders], equipment: ["Barbell", "Bench"]),
            Exercise(id: "seed-incline-db-press", name: "Incline Dumbbell Press", exerciseDescription: "Upper-chest focused press on an incline bench.", primaryMuscle: .chest, secondaryMuscles: [.shoulders, .triceps], equipment: ["Dumbbells", "Bench"]),
            Exercise(id: "seed-pushup", name: "Push-Up", exerciseDescription: "Bodyweight horizontal push.", primaryMuscle: .chest, secondaryMuscles: [.triceps, .core], equipment: ["Bodyweight"]),
            Exercise(id: "seed-pullup", name: "Pull-Up", exerciseDescription: "Bodyweight vertical pull.", primaryMuscle: .back, secondaryMuscles: [.biceps, .forearms], equipment: ["Pull-up Bar"]),
            Exercise(id: "seed-lat-pulldown", name: "Lat Pulldown", exerciseDescription: "Machine vertical pull for the lats.", primaryMuscle: .back, secondaryMuscles: [.biceps], equipment: ["Cable Machine"]),
            Exercise(id: "seed-barbell-row", name: "Barbell Row", exerciseDescription: "Bent-over horizontal pull.", primaryMuscle: .back, secondaryMuscles: [.biceps, .shoulders], equipment: ["Barbell"]),
            Exercise(id: "seed-deadlift", name: "Deadlift", exerciseDescription: "Hip-hinge pull from the floor; full posterior chain.", primaryMuscle: .hamstrings, secondaryMuscles: [.glutes, .back, .forearms], equipment: ["Barbell"]),
            Exercise(id: "seed-squat", name: "Barbell Back Squat", exerciseDescription: "Bilateral knee-and-hip-dominant squat.", primaryMuscle: .quads, secondaryMuscles: [.glutes, .hamstrings, .core], equipment: ["Barbell", "Rack"]),
            Exercise(id: "seed-leg-press", name: "Leg Press", exerciseDescription: "Machine squat pattern.", primaryMuscle: .quads, secondaryMuscles: [.glutes, .hamstrings], equipment: ["Machine"]),
            Exercise(id: "seed-lunge", name: "Walking Lunge", exerciseDescription: "Unilateral squat-pattern lunge.", primaryMuscle: .quads, secondaryMuscles: [.glutes, .hamstrings], equipment: ["Dumbbells"]),
            Exercise(id: "seed-rdl", name: "Romanian Deadlift", exerciseDescription: "Hip-hinge focused on hamstrings and glutes.", primaryMuscle: .hamstrings, secondaryMuscles: [.glutes, .back], equipment: ["Barbell"]),
            Exercise(id: "seed-hip-thrust", name: "Hip Thrust", exerciseDescription: "Glute-focused hip extension.", primaryMuscle: .glutes, secondaryMuscles: [.hamstrings], equipment: ["Barbell", "Bench"]),
            Exercise(id: "seed-ohp", name: "Overhead Press", exerciseDescription: "Standing barbell vertical press.", primaryMuscle: .shoulders, secondaryMuscles: [.triceps, .core], equipment: ["Barbell"]),
            Exercise(id: "seed-lateral-raise", name: "Dumbbell Lateral Raise", exerciseDescription: "Isolation for the side delts.", primaryMuscle: .shoulders, equipment: ["Dumbbells"]),
            Exercise(id: "seed-bicep-curl", name: "Dumbbell Bicep Curl", exerciseDescription: "Isolation elbow flexion.", primaryMuscle: .biceps, equipment: ["Dumbbells"]),
            Exercise(id: "seed-tricep-pushdown", name: "Cable Tricep Pushdown", exerciseDescription: "Isolation elbow extension.", primaryMuscle: .triceps, equipment: ["Cable Machine"]),
            Exercise(id: "seed-plank", name: "Plank", exerciseDescription: "Anti-extension core hold.", primaryMuscle: .core, equipment: ["Bodyweight"]),
            Exercise(id: "seed-calf-raise", name: "Standing Calf Raise", exerciseDescription: "Ankle plantarflexion isolation.", primaryMuscle: .calves, equipment: ["Machine"]),
            Exercise(id: "seed-running", name: "Running", exerciseDescription: "Steady-state or interval cardio.", primaryMuscle: .fullBody, category: .cardio, equipment: ["None"]),
            Exercise(id: "seed-rowing", name: "Rowing Machine", exerciseDescription: "Full-body cardio and conditioning.", primaryMuscle: .fullBody, category: .cardio, equipment: ["Rowing Machine"])
        ]
    }
}
