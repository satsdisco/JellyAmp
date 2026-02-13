import Foundation

/// Parse dates from live recording album names (e.g. "2024-03-15 The Fillmore")
/// Returns nil for studio albums — graceful fallback.
enum ShowDateParser {
    
    static func parse(_ albumName: String) -> Date? {
        guard !albumName.isEmpty else { return nil }
        
        // ISO: 2024-03-15, 2024.03.15, 2024/03/15
        if let match = albumName.firstMatch(of: /(\d{4})[\-\.\/](\d{1,2})[\-\.\/](\d{1,2})/) {
            return makeDate(year: Int(match.1)!, month: Int(match.2)!, day: Int(match.3)!)
        }
        
        // US: 03/15/2024, 03-15-2024
        if let match = albumName.firstMatch(of: /(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})/) {
            return makeDate(year: Int(match.3)!, month: Int(match.1)!, day: Int(match.2)!)
        }
        
        // Short year: 3-15-24
        if let match = albumName.firstMatch(of: /(\d{1,2})\-(\d{1,2})\-(\d{2})\b/) {
            var year = Int(match.3)!
            year = year < 50 ? 2000 + year : 1900 + year
            return makeDate(year: year, month: Int(match.1)!, day: Int(match.2)!)
        }
        
        return nil
    }
    
    static func format(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private static func makeDate(year: Int, month: Int, day: Int) -> Date? {
        guard year >= 1900 && year <= Calendar.current.component(.year, from: Date()) + 1,
              month >= 1 && month <= 12,
              day >= 1 && day <= 31 else { return nil }
        
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        
        guard let date = Calendar.current.date(from: components) else { return nil }
        
        // Verify roundtrip
        let cal = Calendar.current
        guard cal.component(.year, from: date) == year,
              cal.component(.month, from: date) == month,
              cal.component(.day, from: date) == day else { return nil }
        
        return date
    }
}
