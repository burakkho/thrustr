import Foundation

/// Nutrition feature localization keys
enum NutritionKeys {
    static let title = "nutrition.title"
    static let addFood = "nutrition.addFood"
    static let calories = "nutrition.calories"
    static let scanBarcode = "nutrition.scanBarcode"
    
    enum Empty {
        static let firstTitle = "nutrition.empty.first.title"
        static let firstMessage = "nutrition.empty.first.message"
        static let addMeal = "nutrition.empty.addMeal"
        static let addCustomFood = "nutrition.empty.addCustomFood"
        static let todayTitle = "nutrition.empty.todayTitle"
        static let todayMessage = "nutrition.empty.todayMessage"
        static let loadingFoods = "nutrition.empty.loadingFoods"
        // Legacy support - keeping existing ones for backward compatibility
        static let oldTodayTitle = "nutrition.empty.today.title"
        static let oldTodayMessage = "nutrition.empty.today.message"
    }

    enum DailySummary {
        static let title = "nutrition.dailySummary.title"
        static let total = "nutrition.dailySummary.total"
        static let protein = "nutrition.dailySummary.protein"
        static let carbs = "nutrition.dailySummary.carbs"
        static let fat = "nutrition.dailySummary.fat"
    }
    
    enum DailyGoals {
        static let title = "nutrition.dailyGoals.title"
        static let per100g = "nutrition.dailyGoals.per100g"
        static let achievementMessage = "nutrition.dailyGoals.achievementMessage"
    }
    
    enum Test {
        static let addTestFood = "nutrition.test.addTestFood"
        static let testCategory = "nutrition.test.testCategory"
        static let testFood = "nutrition.test.testFood"
        static let clear = "nutrition.test.clear"
        static let addedSuccessfully = "nutrition.test.addedSuccessfully"
        static let clearedSuccessfully = "nutrition.test.clearedSuccessfully"
    }
    
    enum FoodSelection {
        static let title = "nutrition.foodSelection.title"
        static let searchPlaceholder = "nutrition.foodSelection.searchPlaceholder"
        static let clear = "nutrition.foodSelection.clear"
        static let all = "nutrition.foodSelection.all"
        static let cancel = "nutrition.foodSelection.cancel"
        static let addNew = "nutrition.foodSelection.addNew"
        static let noResults = "nutrition.foodSelection.noResults"
        static let noResultsForSearch = "nutrition.foodSelection.noResultsForSearch"
        static let tryDifferentTerms = "nutrition.foodSelection.tryDifferentTerms"
        static let localResults = "nutrition.foodSelection.localResults"
    }

    enum Scan {
        static let scanned = "nutrition.scan.scanned"
        static let cached = "nutrition.scan.cached"
        static let existing = "nutrition.scan.existing"
        static let notFound = "nutrition.scan.notFound"
        static let networkError = "nutrition.scan.networkError"
        static let rateLimited = "nutrition.scan.rateLimited"
        static let invalidBarcode = "nutrition.scan.invalidBarcode"
    }
    
    enum MealEntry {
        static let title = "nutrition.mealEntry.title"
        static let addToMeal = "nutrition.mealEntry.addToMeal"
        static let cancel = "nutrition.mealEntry.cancel"
        static let portion = "nutrition.mealEntry.portion"
        static let portionGrams = "nutrition.mealEntry.portionGrams"
        static let portionOz = "nutrition.mealEntry.portionOz"
        static let portionOunces = "nutrition.mealEntry.portionOunces"
        static let meal = "nutrition.mealEntry.meal"
        static let total = "nutrition.mealEntry.total"
        static let per100gCalories = "nutrition.mealEntry.per100gCalories"
        static let macroInfo = "nutrition.mealEntry.macroInfo"
        
        enum MealTypes {
            static let breakfast = "nutrition.mealEntry.mealTypes.breakfast"
            static let lunch = "nutrition.mealEntry.mealTypes.lunch"
            static let dinner = "nutrition.mealEntry.mealTypes.dinner"
            static let snack = "nutrition.mealEntry.mealTypes.snack"
        }
    }
    
    enum CustomFood {
        static let title = "nutrition.customFood.title"
        static let newFood = "nutrition.customFood.newFood"
        static let addNewFood = "nutrition.customFood.addNewFood"
        static let subtitle = "nutrition.customFood.subtitle"
        static let basicInfo = "nutrition.customFood.basicInfo"
        static let foodName = "nutrition.customFood.foodName"
        static let foodNameRequired = "nutrition.customFood.foodNameRequired"
        static let foodNamePlaceholder = "nutrition.customFood.foodNamePlaceholder"
        static let brand = "nutrition.customFood.brand"
        static let brandOptional = "nutrition.customFood.brandOptional"
        static let brandPlaceholder = "nutrition.customFood.brandPlaceholder"
        static let category = "nutrition.customFood.category"
        static let nutritionValues = "nutrition.customFood.nutritionValues"
        static let per100g = "nutrition.customFood.per100g"
        static let per100gImperial = "nutrition.customFood.per100gImperial"
        static let caloriesRequired = "nutrition.customFood.caloriesRequired"
        static let protein = "nutrition.customFood.protein"
        static let carbs = "nutrition.customFood.carbs"
        static let fat = "nutrition.customFood.fat"
        static let preview = "nutrition.customFood.preview"
        static let addFood = "nutrition.customFood.addFood"
        static let cancel = "nutrition.customFood.cancel"
        static let error = "nutrition.customFood.error"
        static let ok = "nutrition.customFood.ok"
    }
    
    enum Favorites {
        static let favorites = "nutrition.favorites.favorites"
        static let recent = "nutrition.favorites.recent"
        static let popular = "nutrition.favorites.popular"
        static let timesUsed = "nutrition.favorites.timesUsed"
        static let emptyFavorites = "nutrition.favorites.emptyFavorites"
        static let emptyFavoritesDesc = "nutrition.favorites.emptyFavoritesDesc"
        static let emptyRecent = "nutrition.favorites.emptyRecent"
        static let emptyRecentDesc = "nutrition.favorites.emptyRecentDesc"
    }
    
    enum Common {
        static let addFood = "nutrition.common.addFood"
    }
    
    enum PortionInput {
        static let grams = "nutrition.portionInput.grams"
        static let serving = "nutrition.portionInput.serving"
        static let title = "nutrition.portionInput.title"
        static let custom = "nutrition.portionInput.custom"
        static let customAmount = "nutrition.portionInput.customAmount"
        static let set = "nutrition.portionInput.set"
    }
    
    enum Analytics {
        static let title = "nutrition.analytics.title"
        static let weeklyAnalysis = "nutrition.analytics.weeklyAnalysis"
        static let dailyCalories = "nutrition.analytics.dailyCalories"
        static let weeklyAverage = "nutrition.analytics.weeklyAverage"
    }
    
    enum Units {
        static let kcal = "nutrition.units.kcal"
        static let grams = "nutrition.units.grams"
        static let g = "nutrition.units.g"
        static let oz = "nutrition.units.oz"
    }
    
    enum Days {
        static let sunday = "nutrition.days.sunday"
        static let monday = "nutrition.days.monday"
        static let tuesday = "nutrition.days.tuesday"
        static let wednesday = "nutrition.days.wednesday"
        static let thursday = "nutrition.days.thursday"
        static let friday = "nutrition.days.friday"
        static let saturday = "nutrition.days.saturday"
    }
    
    enum Errors {
        static let noFoodSelected = "nutrition.error.noFoodSelected"
        static let noFoodSelectedDesc = "nutrition.error.noFoodSelectedDesc"
        static let pleaseTryAgain = "nutrition.error.pleaseTryAgain"
        static let invalidBarcode = "nutrition.error.invalidBarcode"
        static let productNotFound = "nutrition.error.productNotFound"
        static let networkUnavailable = "nutrition.error.networkUnavailable"
        static let decodingFailed = "nutrition.error.decodingFailed"
        static let invalidResponse = "nutrition.error.invalidResponse"
        static let serverError = "nutrition.error.serverError"
    }
    
    enum Actions {
        static let close = "nutrition.actions.close"
        static let retry = "nutrition.actions.retry"
        static let tryAgain = "nutrition.actions.tryAgain"
        static let cancel = "nutrition.actions.cancel"
        static let scanAgain = "nutrition.actions.scanAgain"
    }
    
    enum Categories {
        static let all = "nutrition.categories.all"
        static let meat = "nutrition.categories.meat"
        static let dairy = "nutrition.categories.dairy"
        static let grains = "nutrition.categories.grains"
        static let vegetables = "nutrition.categories.vegetables"
        static let fruits = "nutrition.categories.fruits"
        static let nuts = "nutrition.categories.nuts"
        static let beverages = "nutrition.categories.beverages"
        static let snacks = "nutrition.categories.snacks"
        static let other = "nutrition.categories.other"
    }
    
    enum Labels {
        static let off = "nutrition.labels.off"
        static let serving = "nutrition.labels.serving"
        static let servingSize = "nutrition.labels.servingSize"
        static let portionEntry = "nutrition.labels.portionEntry"
    }
    
    enum Camera {
        static let failedToStart = "nutrition.camera.failedToStart"
        static let permissionRequired = "nutrition.camera.permissionRequired"
        static let openSettings = "nutrition.camera.openSettings"
    }
}