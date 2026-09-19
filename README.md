# GymTracker

A native iOS app for logging gym workouts, tracking progress over time, and getting honest, rule-based feedback on whether your training is actually optimal — built with SwiftUI, SwiftData, and Swift Charts.

**Made by Himnish**

---

## Features

- **Daily workout logging** — start a session, add exercises, log sets with weight, reps, warmup flags, and RPE
- **Progress tracking** — per-exercise strength trend (estimated 1RM via the Epley formula), weekly volume, session history, streaks
- **Training analysis engine** — a transparent, rule-based system that checks:
  - Weekly training frequency vs. your stated availability
  - Working sets per muscle group vs. typical ranges for your experience level
  - Push/pull and quad/hamstring balance
  - Whether your rep ranges match your actual goal (strength / hypertrophy / endurance / fat loss)
  - Recovery spacing between sessions hitting the same muscle group
  - Progressive overload trend — flags plateaus automatically
- **Exercise library** — seeded with 20 common exercises out of the box, plus live search against the free [wger.de](https://wger.de) open exercise database, plus support for fully custom exercises
- **Personal profile** — goal, experience level, training days per week, body weight, injuries/limitations note
- **Dark, distinctive UI** — card-based layout, electric-lime accent, native Swift Charts throughout

## Tech Stack

- **SwiftUI** — all UI, no UIKit
- **SwiftData** — local, on-device persistence (no account, no server, your data stays on your phone)
- **Swift Charts** — volume charts, strength trend lines
- **wger.de REST API** — free, open, no API key required, used for exercise data enrichment

## Getting Started

Requires Xcode 15+ and iOS 17+ (SwiftData and Swift Charts both need iOS 17).

1. Clone this repo
2. Open `GymTracker.xcodeproj` in Xcode
3. Select a simulator or your own iPhone as the run destination
4. ⌘R to build and run

No API keys, no `.plist` config, no third-party account sign-in required.

## Project Structure

```
GymTracker/
├── GymTrackerApp.swift          # App entry point, SwiftData container
├── Models/
│   ├── Exercise.swift            # Exercise data model
│   ├── WorkoutSession.swift      # Logged session + individual sets
│   └── UserProfile.swift         # Goal, experience, availability
├── Services/
│   ├── ExerciseAPIService.swift  # wger.de integration
│   ├── ExerciseSeedData.swift    # Bundled offline-first exercise set
│   └── WorkoutAnalyzer.swift     # The "is this optimal?" analysis engine
├── Theme/
│   └── AppTheme.swift            # Centralized colors, gradients, card styling
├── Components/
│   └── StatCard.swift            # Reusable stat cards, insight rows, volume bars
└── Views/
    ├── ContentView.swift         # Root tab bar
    ├── OnboardingView.swift      # First-launch setup
    ├── DashboardView.swift       # Weekly stats, volume chart, recent sessions
    ├── LogWorkoutView.swift      # Session logging flow
    ├── ExerciseLibraryView.swift # Browse/search exercises
    ├── ExerciseDetailView.swift  # Exercise info + personal progress chart
    ├── AddCustomExerciseView.swift
    ├── AnalysisView.swift        # Full insight feed + volume breakdown
    └── SplashView.swift          # Launch screen
```

## How the Analysis Engine Works

`WorkoutAnalyzer.swift` is intentionally not a black box. Every threshold — weekly volume landmarks, ideal rep ranges per goal, recovery windows — lives in plain, readable Swift in that one file, based on commonly-cited general strength-training principles. Nothing is hidden behind an API call or a model you can't inspect.

This is general training guidance, not medical or professional coaching advice — the Analysis tab always shows that disclaimer. If you have pain, an injury, or a health condition, check with a doctor or physical therapist before changing your program.

## Roadmap

Shipped:
- [x] Workout logging, progress tracking, and rule-based training analysis
- [x] wger.de exercise library integration

Planned:
- [ ] **Exercise form videos** — short reference clips per exercise (likely sourced or linked from an open video/exercise database) so new lifters can check their form, alongside future in-app form cues or checklists
- [ ] HealthKit integration (auto-import body weight, active energy)
- [ ] Apple Watch companion app for logging sets mid-workout
- [ ] CloudKit sync across devices
- [ ] Push notifications / rest-day reminders
- [ ] Exercise-level screening against the injuries/limitations note in Profile

Contributions and ideas welcome once this is public — open an issue if you spot a bug or have a feature request.

## Data Source

Exercise data is enriched from [wger.de](https://wger.de/en/software/api), an open-source, free fitness database. Thanks to that project for making it publicly accessible without requiring an API key.

## License

Personal project — license not yet decided.
