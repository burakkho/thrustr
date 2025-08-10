//
//  WorkoutService.swift
//  SporHocam
//
//  Created by Assistant on 10/8/25.
//

import Foundation
import SwiftData

@MainActor
class WorkoutService: ObservableObject {
    // MARK: - Published Properties
    @Published var weeklyWorkoutCount: Int = 0
    @Published var weeklyVolume: Double = 0
    @Published var weeklyDuration: TimeInterval = 0
    @Published var isLoading: Bool = false
    
    // MARK: - Private Properties
    private var workouts: [Workout] = []
    
    // MARK: - Public Methods
    func loadWorkoutStats(workouts: [Workout]) {
        self.workouts = workouts
        calculateWeeklyStats()
    }
    
    func refreshStats() {
        calculateWeeklyStats()
    }
    
    // MARK: - Private Methods
    private func calculateWeeklyStats() {
        let calendar = Calendar.current
        let now = Date()
        
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else {
            resetStats()
            return
        }
        
        let thisWeekWorkouts = workouts.filter { workout in
            workout.startTime >= weekStart && workout.startTime <= now
        }
        
        weeklyWorkoutCount = thisWeekWorkouts.count
        weeklyVolume = thisWeekWorkouts.reduce(0.0) { $0 + $1.totalVolume }
        
        // Calculate duration from start/end time difference
        weeklyDuration = thisWeekWorkouts.reduce(0.0) { total, workout in
            if let endTime = workout.endTime {
                return total + endTime.timeIntervalSince(workout.startTime)
            }
            return total
        }
    }
    
    private func resetStats() {
        weeklyWorkoutCount = 0
        weeklyVolume = 0
        weeklyDuration = 0
    }
    
    // MARK: - Utility Methods
    func getWorkoutsForPeriod(days: Int) -> [Workout] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        return workouts.filter { workout in
            workout.startTime >= startDate
        }.sorted { $0.startTime > $1.startTime }
    }
    
    func getWorkoutStats(for workout: Workout) -> (sets: Int, volume: Double, duration: String) {
        // Count total exercise sets across all parts
        let totalSets = workout.parts.reduce(0) { partTotal, part in
            partTotal + part.exerciseSets.count
        }
        
        let volume = workout.totalVolume
        
        // Calculate duration from start/end time
        let duration: TimeInterval
        if let endTime = workout.endTime {
            duration = endTime.timeIntervalSince(workout.startTime)
        } else {
            duration = 0
        }
        
        return (sets: totalSets, volume: volume, duration: formatDuration(duration))
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)sa \(minutes)dk"
        } else {
            return "\(minutes)dk"
        }
    }
}
