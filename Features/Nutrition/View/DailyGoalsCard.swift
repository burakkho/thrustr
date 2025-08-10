import SwiftUI
import SwiftData

struct DailyGoalsCard: View {
    let nutritionEntries: [NutritionEntry]
    @Query private var users: [User]
    
    private var currentUser: User? {
        users.first
    }
    
    private var todaysNutrition: (calories: Double, protein: Double, carbs: Double, fat: Double) {
        let today = Calendar.current.startOfDay(for: Date())
        let todaysEntries = nutritionEntries.filter {
            Calendar.current.isDate($0.date, inSameDayAs: today)
        }
        
        return (
            calories: todaysEntries.reduce(0) { $0 + $1.calories },
            protein: todaysEntries.reduce(0) { $0 + $1.protein },
            carbs: todaysEntries.reduce(0) { $0 + $1.carbs },
            fat: todaysEntries.reduce(0) { $0 + $1.fat }
        )
    }
    
    var body: some View {
        if let user = currentUser {
            VStack(alignment: .leading, spacing: 16) {
                Text("Günlük Hedefler")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                
                HStack(spacing: 20) {
                    // Kalori progress
                    GoalProgressRing(
                        current: todaysNutrition.calories,
                        goal: user.dailyCalorieGoal,
                        title: "Kalori",
                        unit: "kcal",
                        color: .orange
                    )
                    
                    VStack(spacing: 12) {
                        // Protein
                        GoalProgressBar(
                            current: todaysNutrition.protein,
                            goal: user.dailyProteinGoal,
                            title: "Protein",
                            unit: "g",
                            color: .red
                        )
                        
                        // Carbs
                        GoalProgressBar(
                            current: todaysNutrition.carbs,
                            goal: user.dailyCarbGoal,
                            title: "Carbs",
                            unit: "g",
                            color: .blue
                        )
                        
                        // Fat
                        GoalProgressBar(
                            current: todaysNutrition.fat,
                            goal: user.dailyFatGoal,
                            title: "Fat",
                            unit: "g",
                            color: .yellow
                        )
                    }
                }
                .padding(.horizontal)
                
                // Achievement message
                if todaysNutrition.calories >= user.dailyCalorieGoal * 0.8 {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Harika! Hedefe yaklaşıyorsun! 🎉")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

struct GoalProgressRing: View {
    let current: Double
    let goal: Double
    let title: String
    let unit: String
    let color: Color
    
    private var progress: Double {
        min(current / goal, 1.0)
    }
    
    private var percentage: Int {
        Int(progress * 100)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(), value: progress)
                
                VStack(spacing: 2) {
                    Text("\(percentage)%")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                    
                    Text("\(Int(current))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("/ \(Int(goal)) \(unit)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct GoalProgressBar: View {
    let current: Double
    let goal: Double
    let title: String
    let unit: String
    let color: Color
    
    private var progress: Double {
        min(current / goal, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(current))/\(Int(goal))\(unit)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(color.opacity(0.2))
                    .frame(height: 6)
                    .cornerRadius(3)
                
                Rectangle()
                    .fill(color)
                    .frame(width: max(0, progress * 120), height: 6)
                    .cornerRadius(3)
                    .animation(.spring(), value: progress)
            }
            .frame(width: 120)
        }
    }
}

#Preview {
    DailyGoalsCard(nutritionEntries: [])
        .modelContainer(for: [Food.self, NutritionEntry.self, User.self], inMemory: true)
}
