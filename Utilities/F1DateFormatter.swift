import Foundation

struct F1DateFormatter {
    
    /// Format a date as "Mar 8" style
    static func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    /// Format a date as "Saturday, March 8"
    static func fullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
    
    /// Format time as "14:00" (24h local)
    static func time(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    /// Format as "Sat, Mar 8 • 14:00"
    static func sessionDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d • HH:mm"
        return formatter.string(from: date)
    }
    
    /// Day of week abbreviated
    static func dayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    /// Countdown text from a date
    static func countdown(to date: Date) -> String {
        let interval = date.timeIntervalSince(Date())
        guard interval > 0 else { return "Now" }
        
        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
