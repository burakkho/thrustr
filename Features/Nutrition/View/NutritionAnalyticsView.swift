import SwiftUI
import SwiftData

struct NutritionAnalyticsView: View {
    let nutritionEntries: [NutritionEntry]
    
    private var weeklyData: [DayData] {
        let calendar = Calendar.current
        let today = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        
        var dailyTotals: [Date: (calories: Double, protein: Double, carbs: Double, fat: Double)] = [:]
        
        // Son 7 günü hesapla
        for entry in nutritionEntries {
            let dayStart = calendar.startOfDay(for: entry.date)
            
            if dayStart >= calendar.startOfDay(for: weekAgo) && dayStart <= calendar.startOfDay(for: today) {
                if let existing = dailyTotals[dayStart] {
                    dailyTotals[dayStart] = (
                        calories: existing.calories + entry.calories,
                        protein: existing.protein + entry.protein,
                        carbs: existing.carbs + entry.carbs,
                        fat: existing.fat + entry.fat
                    )
                } else {
                    dailyTotals[dayStart] = (
                        calories: entry.calories,
                        protein: entry.protein,
                        carbs: entry.carbs,
                        fat: entry.fat
                    )
                }
            }
        }
        
        // 7 günlük veri oluştur
        var weekData: [DayData] = []
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -6 + i, to: today) ?? today
            let dayStart = calendar.startOfDay(for: date)
            let dayName = calendar.component(.weekday, from: date)
            let dayNames = ["", "Paz", "Pzt", "Sal", "Çar", "Per", "Cum", "Cmt"]
            
            if let data = dailyTotals[dayStart] {
                weekData.append(DayData(
                    date: date,
                    dayName: dayNames[dayName],
                    calories: data.calories,
                    protein: data.protein,
                    carbs: data.carbs,
                    fat: data.fat
                ))
            } else {
                weekData.append(DayData(
                    date: date,
                    dayName: dayNames[dayName],
                    calories: 0,
                    protein: 0,
                    carbs: 0,
                    fat: 0
                ))
            }
        }
        
        return weekData
    }
    
    private var maxCalories: Double {
        weeklyData.map { $0.calories }.max() ?? 1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Haftalık Analiz")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            // Kalori chart
            VStack(alignment: .leading, spacing: 8) {
                Text("Günlük Kalori")
                    .font(.headline)
                    .padding(.horizontal)
                
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(weeklyData, id: \.date) { day in
                        VStack(spacing: 4) {
                            // Bar
                            Rectangle()
                                .fill(day.calories > 0 ? Color.orange : Color.gray.opacity(0.3))
                                .frame(width: 32, height: max(4, (day.calories / maxCalories) * 100))
                                .cornerRadius(4)
                            
                            // Kalori değeri
                            Text("\(Int(day.calories))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            // Gün adı
                            Text(day.dayName)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Macro özeti
            VStack(alignment: .leading, spacing: 12) {
                Text("Haftalık Ortalama")
                    .font(.headline)
                    .padding(.horizontal)
                
                let avgCalories = weeklyData.map { $0.calories }.reduce(0, +) / 7
                let avgProtein = weeklyData.map { $0.protein }.reduce(0, +) / 7
                let avgCarbs = weeklyData.map { $0.carbs }.reduce(0, +) / 7
                let avgFat = weeklyData.map { $0.fat }.reduce(0, +) / 7
                
                HStack(spacing: 20) {
                    MacroSummaryView(value: Int(avgCalories), label: "Kalori", color: .orange, unit: "kcal")
                    MacroSummaryView(value: Int(avgProtein), label: "Protein", color: .red, unit: "g")
                    MacroSummaryView(value: Int(avgCarbs), label: "Carbs", color: .blue, unit: "g")
                    MacroSummaryView(value: Int(avgFat), label: "Fat", color: .yellow, unit: "g")
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct DayData {
    let date: Date
    let dayName: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
}

struct MacroSummaryView: View {
    let value: Int
    let label: String
    let color: Color
    let unit: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(color)
            Text(unit)
                .font(.caption2)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NutritionAnalyticsView(nutritionEntries: [])
        .modelContainer(for: [Food.self, NutritionEntry.self], inMemory: true)
}
