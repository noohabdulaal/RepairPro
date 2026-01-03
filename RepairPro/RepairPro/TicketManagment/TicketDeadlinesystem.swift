//
//  TicketDeadlineSystem.swift (FIXED)
//  Auto-generates deadline based on PRIORITY + STATUS
//  FIXED: DateFormatter method corrected
//

import Foundation

// MARK: - Ticket Priority Enum
// Defines the different priority levels a ticket can have
enum TicketPriority: String, Codable {
    case critical = "Critical"   // Most urgent - needs immediate attention
    case high = "High"          // Important - needs attention soon
    case medium = "Medium"      // Normal priority
    case low = "Low"           // Can wait - not urgent
    
    // Color assigned to each priority level (hex format)
    var color: String {
        switch self {
        case .critical: return "#FF0000"  // Red (danger!)
        case .high: return "#FF6B00"      // Orange (important)
        case .medium: return "#FFB800"    // Yellow (moderate)
        case .low: return "#00C853"       // Green (can wait)
        }
    }
}

// MARK: - Ticket Status Enum
// Defines the different stages a ticket goes through
enum TicketStatus: String, Codable {
    case pending = "Pending"         // Just created, waiting to be assigned
    case assigned = "Assigned"       // Assigned to a technician
    case inProgress = "In Progress"  // Being worked on
    case complete = "Complete"       // Finished!
}

// MARK: - Deadline Calculator
// Calculates automatic deadlines for tickets based on priority and status
class DeadlineCalculator {
    
    // MARK: - Calculate Deadline Method
    // Main method to calculate when a ticket should be completed
    // Parameters:
    //   - status: Current ticket status
    //   - priority: How urgent the ticket is
    //   - createdDate: When the ticket was created (default = now)
    // Returns: The calculated deadline as a Date
    static func calculateDeadline(
        status: TicketStatus,
        priority: TicketPriority,
        createdDate: Date = Date()
    ) -> Date {
        
        // Calculate how many hours to add based on status and priority
        let hoursToAdd = getDeadlineHours(status: status, priority: priority)
        
        // Add those hours to the creation date
        let deadline = Calendar.current.date(
            byAdding: .hour,
            value: hoursToAdd,
            to: createdDate
        ) ?? createdDate
        
        // For non-critical tickets, skip weekends
        if priority != .critical {
            return adjustForWeekends(deadline)
        }
        
        return deadline
    }
    
    // MARK: - Get Deadline Hours
    // Calculates how many hours until deadline based on priority and status
    // Parameters:
    //   - status: Current ticket status
    //   - priority: Priority level
    // Returns: Number of hours to add
    private static func getDeadlineHours(
        status: TicketStatus,
        priority: TicketPriority
    ) -> Int {
        
        // Base hours determined by priority level
        let baseHours: Int
        switch priority {
        case .critical:
            baseHours = 4      // 4 hours (same day!)
        case .high:
            baseHours = 24     // 1 day
        case .medium:
            baseHours = 72     // 3 days
        case .low:
            baseHours = 168    // 7 days (1 week)
        }
        
        // Status multiplier adjusts deadline based on progress
        let statusMultiplier: Double
        switch status {
        case .inProgress:
            statusMultiplier = 0.8   // 20% faster (being actively worked on)
        case .assigned:
            statusMultiplier = 1.0   // Normal time (assigned to someone)
        case .pending:
            statusMultiplier = 1.3   // 30% slower (not assigned yet)
        case .complete:
            statusMultiplier = 1.0   // Doesn't matter, already done
        }
        
        // Multiply base hours by the status multiplier
        return Int(Double(baseHours) * statusMultiplier)
    }
    
    // MARK: - Adjust for Weekends
    // If deadline falls on weekend, move it to Monday
    // Parameters:
    //   - date: The original deadline date
    // Returns: Adjusted date (Monday if weekend, otherwise unchanged)
    private static func adjustForWeekends(_ date: Date) -> Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        // Weekday values: 1=Sunday, 2=Monday, ..., 7=Saturday
        // If deadline falls on Saturday (7) or Sunday (1), move to Monday
        if weekday == 7 {
            // Saturday → Move to Monday (add 2 days)
            return calendar.date(byAdding: .day, value: 2, to: date) ?? date
        } else if weekday == 1 {
            // Sunday → Move to Monday (add 1 day)
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        
        // Weekday, no change needed
        return date
    }
    
    // MARK: - Format Deadline for Display
    // Converts Date to readable string like "Jan 15, 2025 14:30"
    // Parameters:
    //   - date: The deadline date to format
    // Returns: Formatted string
    static func formatDeadline(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy HH:mm"
        return formatter.string(from: date)  // ✅ FIXED: string(from:) not format()
    }
    
    // MARK: - Format Deadline for Firebase
    // Converts Date to ISO8601 string for saving to database
    // Parameters:
    //   - date: The deadline date
    // Returns: ISO8601 formatted string (e.g., "2025-01-15T14:30:00Z")
    static func formatDeadlineForFirebase(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: date)
    }
    
    // MARK: - Get Time Remaining
    // Calculates and formats how much time is left until deadline
    // Parameters:
    //   - deadline: The deadline date
    // Returns: Friendly text like "2 days left", "5 hours left"
    static func timeRemaining(until deadline: Date) -> String {
        let now = Date()
        // Calculate difference between now and deadline
        let components = Calendar.current.dateComponents(
            [.day, .hour, .minute],
            from: now,
            to: deadline
        )
        
        // Return the largest meaningful time unit
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
    // Determines if deadline has passed
    // Parameters:
    //   - deadline: The deadline date to check
    // Returns: true if past deadline, false otherwise
    static func isOverdue(_ deadline: Date) -> Bool {
        return Date() > deadline
    }
    
    // MARK: - Get Urgency Level
    // Determines how urgent a ticket is based on time remaining
    // Parameters:
    //   - deadline: The deadline date
    // Returns: Urgency level enum value
    static func getUrgencyLevel(for deadline: Date) -> UrgencyLevel {
        // Calculate hours remaining until deadline
        let hoursRemaining = Calendar.current.dateComponents(
            [.hour],
            from: Date(),
            to: deadline
        ).hour ?? 0
        
        // Categorize urgency based on hours remaining
        if hoursRemaining < 0 {
            return .overdue      // Past deadline!
        } else if hoursRemaining < 4 {
            return .urgent       // Less than 4 hours - very urgent!
        } else if hoursRemaining < 24 {
            return .soon         // Less than 1 day - approaching
        } else {
            return .normal       // More than 1 day - okay
        }
    }
}

// MARK: - Urgency Level Enum
// Categorizes how urgent a ticket is based on time remaining
enum UrgencyLevel {
    case overdue    // Deadline has passed
    case urgent     // Very little time left
    case soon       // Approaching deadline
    case normal     // Plenty of time
    
    // Color for this urgency level (hex format)
    var color: String {
        switch self {
        case .overdue: return "#FF0000"  // Red (danger!)
        case .urgent: return "#FF6B00"   // Orange (warning!)
        case .soon: return "#FFB800"     // Yellow (heads up)
        case .normal: return "#4CAF50"   // Green (all good)
        }
    }
    
    // Emoji icon for this urgency level
    var emoji: String {
        switch self {
        case .overdue: return "🚨"  // Emergency siren
        case .urgent: return "⚠️"   // Warning sign
        case .soon: return "⏰"     // Alarm clock
        case .normal: return "✅"   // Check mark
        }
    }
}
