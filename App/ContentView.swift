import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false

    var body: some View {
        if onboardingCompleted {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Exercise.self, User.self, Workout.self, WorkoutPart.self, ExerciseSet.self], inMemory: true)
}
