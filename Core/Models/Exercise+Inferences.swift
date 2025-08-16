extension Exercise {
    var inferredWorkoutPartType: WorkoutPartType {
        ExerciseCategory(rawValue: self.category)?.toWorkoutPartType() ?? .powerStrength
    }
}


