import SwiftUI
import SwiftData
import Foundation

// MARK: - Nutrition Totals for Performance
struct NutritionTotals: Equatable {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    
    static let zero = NutritionTotals(calories: 0, protein: 0, carbs: 0, fat: 0)
}

struct DailyNutritionSummary: View {
    let nutritionEntries: [NutritionEntry]
    @State private var editingEntry: NutritionEntry?
    @State private var showingEditSheet: Bool = false
    @State private var saveErrorMessage: String? = nil
    
    // PERFORMANCE: Cache expensive calculations
    @State private var cachedTotals: NutritionTotals = .zero
    @State private var cachedTodaysEntries: [NutritionEntry] = []
    @State private var lastCacheDate: Date = Date.distantPast
    
    // İstenen sıralama: Kahvaltı → Öğle → Akşam → Ara Öğün
    private let mealOrderKeys: [String] = ["breakfast", "lunch", "dinner", "snack"]
    private let horizontalPadding: CGFloat = 16
    
    // PERFORMANCE: Cached computed properties
    private var todaysEntries: [NutritionEntry] {
        return cachedTodaysEntries
    }
    
    private var totalCalories: Double {
        return cachedTotals.calories
    }
    
    private var totalProtein: Double {
        return cachedTotals.protein
    }
    
    private var totalCarbs: Double {
        return cachedTotals.carbs
    }
    
    private var totalFat: Double {
        return cachedTotals.fat
    }
    
    // PERFORMANCE: Cache management
    private func updateCacheIfNeeded() {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Only recalculate if day changed or data changed
        if !Calendar.current.isDate(lastCacheDate, inSameDayAs: today) || cachedTodaysEntries.count != todaysEntriesCount {
            let newTodaysEntries = nutritionEntries.filter {
                Calendar.current.isDate($0.date, inSameDayAs: today)
            }
            
            // Calculate all totals in one pass for efficiency
            let newTotals = newTodaysEntries.reduce(NutritionTotals.zero) { totals, entry in
                NutritionTotals(
                    calories: totals.calories + entry.calories,
                    protein: totals.protein + entry.protein,
                    carbs: totals.carbs + entry.carbs,
                    fat: totals.fat + entry.fat
                )
            }
            
            cachedTodaysEntries = newTodaysEntries
            cachedTotals = newTotals
            lastCacheDate = today
        }
    }
    
    private var todaysEntriesCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return nutritionEntries.filter {
            Calendar.current.isDate($0.date, inSameDayAs: today)
        }.count
    }
    
    var body: some View {
        mainContent
            .onAppear {
                updateCacheIfNeeded()
            }
            .onChange(of: nutritionEntries) { _, _ in
                Task { @MainActor in
                    updateCacheIfNeeded()
                }
            }
            .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
                // Update cache every minute to handle day changes
                Task { @MainActor in
                    updateCacheIfNeeded()
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                if let entry = editingEntry {
                    NutritionEntryEditSheet(entry: entry)
                }
            }
            .alert(isPresented: errorAlertBinding) {
                Alert(
                    title: Text(CommonKeys.Onboarding.Common.error.localized),
                    message: Text(saveErrorMessage ?? ""),
                    dismissButton: .default(Text(CommonKeys.Onboarding.Common.ok.localized))
                )
            }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if !todaysEntries.isEmpty {
            summaryContainer
        }
    }
    
    private var summaryContainer: some View {
        VStack(alignment: .leading, spacing: 12) {
            summaryHeader
            mealSections
            totalSummarySection
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal, 8)
    }
    
    private var summaryHeader: some View {
        Text(NutritionKeys.DailySummary.title.localized)
            .font(.title2)
            .fontWeight(.semibold)
            .padding(.horizontal, horizontalPadding)
    }
    
    private var mealSections: some View {
        ForEach(mealOrderKeys, id: \.self) { mealKey in
            MealSectionView(
                mealKey: mealKey,
                entries: todaysEntries.filter { $0.mealType == mealKey },
                onEdit: { entry in
                    editingEntry = entry
                    showingEditSheet = true
                },
                onError: { error in
                    saveErrorMessage = error
                }
            )
        }
    }
    
    private var totalSummarySection: some View {
        TotalSummaryView(
            totalCalories: totalCalories,
            totalProtein: totalProtein,
            totalCarbs: totalCarbs,
            totalFat: totalFat
        )
        .padding(.horizontal, horizontalPadding)
        .padding(.top, 8)
    }
    
    private var errorAlertBinding: Binding<Bool> {
        Binding<Bool>(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )
    }
}

#Preview {
    DailyNutritionSummary(nutritionEntries: [])
        .modelContainer(for: [Food.self, NutritionEntry.self], inMemory: true)
}
