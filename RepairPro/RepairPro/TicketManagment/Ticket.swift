//
//  Ticket.swift (FIXED)
//  Ticket model for maintenance/support tickets
//  ✅ FIXED: Status now defaults to "In Progress" when no technician is assigned
//

import Foundation
import FirebaseFirestore
import UIKit

// MARK: - Ticket Model
// Represents a maintenance/repair ticket in the system
// Codable = can be converted to/from JSON for Firebase
// Identifiable = has a unique ID
struct Ticket: Codable, Identifiable {
    // Firestore document ID - automatically managed by Firebase
    @DocumentID var id: String?
    
    // MARK: - Required Fields
    let ticket_id: Int         // Unique ticket number
    let description: String    // What needs to be fixed/done
    let campus: String         // Which campus/building (e.g., "Campus A, B19")
    let due: String            // Deadline date (ISO8601 format)
    var status: String         // Current status (Assigned, In Progress, Complete)
    var priority: String       // Priority level (High, Medium, Low)
    
    // MARK: - Optional Fields (can be nil)
    var technician_id: Int?      // ID of assigned technician (nil if unassigned)
    var technician: String?      // Technician identifier
    var technician_name: String? // Technician's full name
    var image_url: String?       // URL to attached image
    
    // MARK: - Coding Keys
    // Maps Swift property names to Firebase database field names
    enum CodingKeys: String, CodingKey {
        case id
        case ticket_id
        case description
        case campus
        case due
        case status
        case priority
        case technician_id
        case technician
        case technician_name
        case image_url
    }
    
    // MARK: - Custom Decoder
    // Handles loading ticket data from Firebase and dealing with missing/bad data
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Get the Firestore document ID
        _id = try DocumentID(from: decoder)
        
        // Decode ticket_id - try as Int first, then try as String and convert
        if let ticketIdInt = try? container.decode(Int.self, forKey: .ticket_id) {
            // It's already an integer, use it
            ticket_id = ticketIdInt
        } else if let ticketIdString = try? container.decode(String.self, forKey: .ticket_id),
                  let ticketIdInt = Int(ticketIdString) {
            // It was a string like "123", convert to integer
            ticket_id = ticketIdInt
        } else {
            // Couldn't get ticket_id at all, use 0 as fallback
            ticket_id = 0
        }
        
        // Handle description - use "No description provided" if missing or empty
        if let descValue = try? container.decode(String.self, forKey: .description), !descValue.isEmpty {
            description = descValue
        } else {
            description = "No description provided"
        }
        
        // Handle campus - use "Not specified" if missing or empty
        if let campusValue = try? container.decode(String.self, forKey: .campus), !campusValue.isEmpty {
            campus = campusValue
        } else {
            campus = "Not specified"
        }
        
        // Handle due date - can be String OR Firebase Timestamp
        if let dueString = try? container.decode(String.self, forKey: .due), !dueString.isEmpty {
            // Already a string, use it
            due = dueString
        } else if let timestamp = try? container.decode(Timestamp.self, forKey: .due) {
            // It's a Firebase Timestamp, convert to ISO8601 string
            let formatter = ISO8601DateFormatter()
            due = formatter.string(from: timestamp.dateValue())
        } else {
            // No due date found, default to 7 days from now
            let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
            let formatter = ISO8601DateFormatter()
            due = formatter.string(from: futureDate)
        }
        
        // Handle priority - default to "Medium" if not specified
        if let priorityValue = try? container.decode(String.self, forKey: .priority), !priorityValue.isEmpty {
            priority = priorityValue
        } else {
            priority = "Medium"
        }
        
        // Handle optional technician_id - try as Int first, then as String
        if let techId = try? container.decode(Int.self, forKey: .technician_id) {
            technician_id = techId
        } else if let techIdString = try? container.decode(String.self, forKey: .technician_id),
                  let techId = Int(techIdString) {
            technician_id = techId
        } else {
            // No technician ID found
            technician_id = nil
        }
        
        // Handle optional technician field
        if let techValue = try? container.decode(String.self, forKey: .technician), !techValue.isEmpty {
            technician = techValue
        } else {
            technician = nil
        }
        
        // Handle optional technician_name field
        if let techNameValue = try? container.decode(String.self, forKey: .technician_name), !techNameValue.isEmpty {
            technician_name = techNameValue
        } else {
            technician_name = nil
        }
        
        // Handle optional image_url field
        if let imageValue = try? container.decode(String.self, forKey: .image_url), !imageValue.isEmpty {
            image_url = imageValue
        } else {
            image_url = nil
        }
        
        // ✅ SMART STATUS LOGIC
        // Handle status with intelligent fallback - always default to "In Progress"
        if let statusValue = try? container.decode(String.self, forKey: .status), !statusValue.isEmpty {
            // Status exists in database, use it AS-IS
            status = statusValue
        } else {
            // No status in database, always default to "In Progress"
            // New tickets should start as "In Progress" regardless of technician assignment
            status = "In Progress"
        }
    }
    
    // MARK: - Custom Encoder
    // Handles saving ticket data back to Firebase
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode all required fields
        try container.encode(ticket_id, forKey: .ticket_id)
        try container.encode(description, forKey: .description)
        try container.encode(campus, forKey: .campus)
        try container.encode(due, forKey: .due)
        try container.encode(status, forKey: .status)
        try container.encode(priority, forKey: .priority)
        
        // Encode optional fields only if they have values
        try container.encodeIfPresent(technician_id, forKey: .technician_id)
        try container.encodeIfPresent(technician, forKey: .technician)
        try container.encodeIfPresent(technician_name, forKey: .technician_name)
        try container.encodeIfPresent(image_url, forKey: .image_url)
    }
}

// MARK: - Helper Extensions
// Computed properties to make working with tickets easier
extension Ticket {
    
    // MARK: - Display Technician Name
    // Returns technician name with fallback logic
    // Tries: technician_name → technician → "Unassigned"
    var displayTechnicianName: String {
        if let name = technician_name, !name.isEmpty {
            // Use technician_name if it exists
            return name
        } else if let tech = technician, !tech.isEmpty {
            // Fall back to technician field
            return tech
        } else {
            // No technician assigned
            return "Unassigned"
        }
    }
    
    // MARK: - Formatted Due Date
    // Converts "2025-01-15T10:30:00Z" to "Jan 15, 10:30"
    var formattedDueDate: String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: due) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM dd, HH:mm"
            return displayFormatter.string(from: date)
        }
        // If parsing fails, return raw date string
        return due
    }
    
    // MARK: - Days Remaining
    // Calculates how many days until the deadline
    // Returns negative number if overdue
    var daysRemaining: Int {
        let formatter = ISO8601DateFormatter()
        guard let dueDate = formatter.date(from: due) else {
            return 0
        }
        
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: now, to: dueDate)
        return components.day ?? 0
    }
    
    // MARK: - Days Remaining Text
    // Converts days remaining to friendly text
    // Examples: "3 days left", "Due today", "2 days overdue"
    var daysRemainingText: String {
        let days = daysRemaining
        
        if days < 0 {
            // Overdue - show as positive number with "overdue"
            return "\(abs(days)) days overdue"
        } else if days == 0 {
            // Due today
            return "Due today"
        } else if days == 1 {
            // Singular form
            return "1 day left"
        } else {
            // Plural form
            return "\(days) days left"
        }
    }
    
    // MARK: - Is Overdue Check
    // Returns true if deadline has passed
    var isOverdue: Bool {
        return daysRemaining < 0
    }
    
    // MARK: - Priority Color
    // Returns color based on priority level
    var priorityColor: UIColor {
        switch priority.lowercased() {
        case "high", "urgent", "critical":
            return UIColor(red: 255/255, green: 162/255, blue: 19/255, alpha: 1) // Orange #FFA213
        case "medium", "normal":
            return UIColor(red: 255/255, green: 162/255, blue: 19/255, alpha: 1) // Orange #FFA213
        case "low":
            return UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1) // Blue #00476F
        default:
            return UIColor(red: 255/255, green: 162/255, blue: 19/255, alpha: 1) // Default Orange
        }
    }
    
    // MARK: - Status Color
    // Returns color based on ticket status
    var statusColor: UIColor {
        switch status.lowercased() {
        case "completed", "resolved", "done":
            return UIColor(red: 52/255, green: 199/255, blue: 89/255, alpha: 1) // Green (finished)
        case "assigned":
            return UIColor(red: 255/255, green: 162/255, blue: 19/255, alpha: 1) // Orange #FFA213 (assigned to technician)
        case "in progress":
            return UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1) // Blue #00476F (working on it)
        case "pending", "new", "open":
            return UIColor(red: 255/255, green: 59/255, blue: 48/255, alpha: 1) // Red (waiting)
        default:
            return .systemGray
        }
    }
    
    // MARK: - Accent Color (Card Stripe)
    // Color for the left stripe on ticket cards
    // Alternates between blue and orange based on ticket ID
    var accentColor: UIColor {
        // Even ticket IDs get blue, odd ticket IDs get orange
        return ticket_id % 2 == 0 ?
            UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1) :  // Blue
            UIColor(red: 255/255, green: 162/255, blue: 19/255, alpha: 1)  // Orange
    }
}
