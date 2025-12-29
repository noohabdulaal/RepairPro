//
//  TicketDeadlineSystem.swift (FIXED)
//  Auto-generates deadline based on PRIORITY + STATUS
//  FIXED: DateFormatter method corrected
//

import Foundation

// MARK: - Ticket Priority
enum TicketPriority: String, Codable {
    case critical = "Critical"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    var color: String {
        switch self {
        case .critical: return "#FF0000"  // Red
        case .high: return "#FF6B00"      // Orange
        case .medium: return "#FFB800"    // Yellow
        case .low: return "#00C853"       // Green
        }
    }
}

// MARK: - Ticket Status
enum TicketStatus: String, Codable {
    case pending = "Pending"
    case assigned = "Assigned"
    case inProgress = "In Progress"
    case complete = "Complete"
}

// MARK: - Deadline Calculator
class DeadlineCalculator {
    
    // MARK: - Calculate Deadline
    static func calculateDeadline(
        status: TicketStatus,
        priority: TicketPriority,
        createdDate: Date = Date()
    ) -> Date {
        
        let hoursToAdd = getDeadlineHours(status: status, priority: priority)
        
        // Add hours to current date
        let deadline = Calendar.current.date(
            byAdding: .hour,
            value: hoursToAdd,
            to: createdDate
        ) ?? createdDate
        
        // Skip weekends for non-critical issues
        if priority != .critical {
            return adjustForWeekends(deadline)
        }
        
        return deadline
    }
    
    // MARK: - Get Deadline Hours Based on Status and Priority
    private static func getDeadlineHours(
        status: TicketStatus,
        priority: TicketPriority
    ) -> Int {
        
        // Base hours by priority
        let baseHours: Int
        switch priority {
        case .critical:
            baseHours = 4      // 4 hours
        case .high:
            baseHours = 24     // 1 day
        case .medium:
            baseHours = 72     // 3 days
        case .low:
            baseHours = 168    // 7 days
        }
        
        // Status multipliers (urgency based on assignment)
        let statusMultiplier: Double
        switch status {
        case .inProgress:
            statusMultiplier = 0.8   // 20% faster (actively being worked on)
        case .assigned:
            statusMultiplier = 1.0   // Normal (assigned to technician)
        case .pending:
            statusMultiplier = 1.3   // 30% slower (not yet assigned)
        case .complete:
            statusMultiplier = 1.0   // Doesn't matter, already done
        }
        
        return Int(Double(baseHours) * statusMultiplier)
    }
    
    // MARK: - Adjust for Weekends
    private static func adjustForWeekends(_ date: Date) -> Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        // If deadline falls on Saturday (7) or Sunday (1)
        if weekday == 7 {
            // Move to Monday
            return calendar.date(byAdding: .day, value: 2, to: date) ?? date
        } else if weekday == 1 {
            // Move to Monday
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        
        return date
    }
    
    // MARK: - Format Deadline String (FIXED)
    static func formatDeadline(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy HH:mm"
        return formatter.string(from: date)  // ✅ FIXED: string(from:) not format()
    }
    
    // MARK: - Format Deadline for Firebase (ISO8601)
    static func formatDeadlineForFirebase(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: date)
    }
    
    // MARK: - Get Time Remaining
    static func timeRemaining(until deadline: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents(
            [.day, .hour, .minute],
            from: now,
            to: deadline
        )
        
        if let days = components.day, days > 0 {
            return "\(days) day\(days == 1 ? "" : "s") left"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") left"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s") left"
        } else {
            return "Overdue"
        }
    }
    
    // MARK: - Check if Overdue
    static func isOverdue(_ deadline: Date) -> Bool {
        return Date() > deadline
    }
    
    // MARK: - Get Urgency Level
    static func getUrgencyLevel(for deadline: Date) -> UrgencyLevel {
        let hoursRemaining = Calendar.current.dateComponents(
            [.hour],
            from: Date(),
            to: deadline
        ).hour ?? 0
        
        if hoursRemaining < 0 {
            return .overdue
        } else if hoursRemaining < 4 {
            return .urgent
        } else if hoursRemaining < 24 {
            return .soon
        } else {
            return .normal
        }
    }
}

// MARK: - Urgency Level
enum UrgencyLevel {
    case overdue
    case urgent
    case soon
    case normal
    
    var color: String {
        switch self {
        case .overdue: return "#FF0000"  // Red
        case .urgent: return "#FF6B00"   // Orange
        case .soon: return "#FFB800"     // Yellow
        case .normal: return "#4CAF50"   // Green
        }
    }
    
    var emoji: String {
        switch self {
        case .overdue: return "🚨"
        case .urgent: return "⚠️"
        case .soon: return "⏰"
        case .normal: return "✅"
        }
    }
}
