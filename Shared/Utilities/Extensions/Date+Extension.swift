import Foundation

extension Date {
    
    // MARK: - Date Formatting
    
    /// Tarih formatı: "12 Ağustos 2025"
    var longDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateStyle = .long
        return formatter.string(from: self)
    }
    
    /// Tarih formatı: "12 Ağu"
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: self)
    }
    
    /// Tarih formatı: "12/08/2025"
    var numericDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: self)
    }
    
    /// Saat formatı: "14:30"
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
    
    /// Tarih + Saat formatı: "12 Ağu 14:30"
    var dateTimeString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMM HH:mm"
        return formatter.string(from: self)
    }
    
    /// Relatif tarih: localized today/yesterday or date string
    var relativeString: String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(self) {
            return DashboardKeys.Activities.today.localized
        } else if calendar.isDateInYesterday(self) {
            return DashboardKeys.Activities.yesterday.localized
        } else if calendar.isDate(self, equalTo: now, toGranularity: .year) {
            // Bu yıl içinde
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "tr_TR")
            formatter.dateFormat = "d MMMM"
            return formatter.string(from: self)
        } else {
            // Başka yıl
            return numericDateString
        }
    }
    
    // MARK: - Date Calculations
    
    /// Günün başlangıcı (00:00:00)
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    /// Günün sonu (23:59:59)
    var endOfDay: Date {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: self)
        return calendar.date(byAdding: .day, value: 1, to: startOfDay)?.addingTimeInterval(-1) ?? self
    }
    
    /// Haftanın başlangıcı (Pazartesi)
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// Ayın başlangıcı
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// Yaş hesaplama
    var age: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: self, to: Date())
        return ageComponents.year ?? 0
    }
    
    /// Bugünden kaç gün önce/sonra
    var daysFromNow: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date().startOfDay, to: self.startOfDay)
        return components.day ?? 0
    }
    
    // MARK: - Date Comparisons
    
    /// Bugün mü?
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    /// Bu hafta mı?
    var isThisWeek: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    /// Bu ay mı?
    var isThisMonth: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }
    
    /// Bu yıl mı?
    var isThisYear: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year)
    }
    
    // MARK: - Workout Specific
    
    /// Antrenman için tarih formatı: localized Today/Yesterday or weekday+date
    var workoutDateString: String {
        if isToday {
            return DashboardKeys.Activities.today.localized
        } else if Calendar.current.isDateInYesterday(self) {
            return DashboardKeys.Activities.yesterday.localized
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "tr_TR")
            formatter.dateFormat = "E, d MMM"
            return formatter.string(from: self)
        }
    }
    
    /// Antrenman süresi formatı: "1s 30d" veya "45d"
    static func formatWorkoutDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)s \(minutes)d"
        } else {
            return "\(minutes)d"
        }
    }
    
    // MARK: - Nutrition Specific
    
    /// Beslenme için hafta günü: "Pazartesi"
    var weekdayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }
    
    /// Beslenme için kısa hafta günü: "Pzt"
    var shortWeekdayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "E"
        return formatter.string(from: self)
    }
    
    // MARK: - Date Creation Helpers
    
    /// Belirtilen gün kadar ekle/çıkar
    func adding(days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
    
    /// Belirtilen hafta kadar ekle/çıkar
    func adding(weeks: Int) -> Date {
        return Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: self) ?? self
    }
    
    /// Belirtilen ay kadar ekle/çıkar
    func adding(months: Int) -> Date {
        return Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }
    
    // MARK: - Progress Tracking
    
    /// İki tarih arasındaki gün sayısı
    func daysBetween(_ date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: self.startOfDay, to: date.startOfDay)
        return abs(components.day ?? 0)
    }
    
    /// Haftanın hangi günü (1=Pazartesi, 7=Pazar)
    var weekdayNumber: Int {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: self)
        // Sunday = 1 in Calendar, but we want Monday = 1
        return weekday == 1 ? 7 : weekday - 1
    }
}
