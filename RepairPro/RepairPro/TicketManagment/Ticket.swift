//
//  Ticket.swift (FIXED)
//  Ticket model for maintenance/support tickets
//  ✅ FIXED: Status now defaults to "In Progress" when no technician is assigned
//

import Foundation
import FirebaseFirestore
import UIKit

struct Ticket: Codable, Identifiable {
    @DocumentID var id: String?
    
    let ticket_id: Int
    let description: String
    let campus: String
    let due: String
    var status: String
    var priority: String
    var technician_id: Int?
    var technician: String?
    var technician_name: String?
    var image_url: String?
    
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
    
    // Custom decoding to handle empty fields and missing data
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode @DocumentID separately
        _id = try DocumentID(from: decoder)
        
        // Decode ticket_id
        if let ticketIdInt = try? container.decode(Int.self, forKey: .ticket_id) {
            ticket_id = ticketIdInt
        } else if let ticketIdString = try? container.decode(String.self, forKey: .ticket_id),
                  let ticketIdInt = Int(ticketIdString) {
            ticket_id = ticketIdInt
        } else {
            ticket_id = 0
        }
        
        // Handle description with fallback
        if let descValue = try? container.decode(String.self, forKey: .description), !descValue.isEmpty {
            description = descValue
        } else {
            description = "No description provided"
        }
        
        // Handle campus with fallback
        if let campusValue = try? container.decode(String.self, forKey: .campus), !campusValue.isEmpty {
            campus = campusValue
        } else {
            campus = "Not specified"
        }
        
        // Handle due date - can be string or timestamp
        if let dueString = try? container.decode(String.self, forKey: .due), !dueString.isEmpty {
            due = dueString
        } else if let timestamp = try? container.decode(Timestamp.self, forKey: .due) {
            let formatter = ISO8601DateFormatter()
            due = formatter.string(from: timestamp.dateValue())
        } else {
            // Default to 7 days from now
            let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
            let formatter = ISO8601DateFormatter()
            due = formatter.string(from: futureDate)
        }
        
        // Handle priority with fallback
        if let priorityValue = try? container.decode(String.self, forKey: .priority), !priorityValue.isEmpty {
            priority = priorityValue
        } else {
            priority = "Medium"
        }
        
        // Handle optional technician_id
        if let techId = try? container.decode(Int.self, forKey: .technician_id) {
            technician_id = techId
        } else if let techIdString = try? container.decode(String.self, forKey: .technician_id),
                  let techId = Int(techIdString) {
            technician_id = techId
        } else {
            technician_id = nil
        }
        
        // Handle optional technician
        if let techValue = try? container.decode(String.self, forKey: .technician), !techValue.isEmpty {
            technician = techValue
        } else {
            technician = nil
        }
        
        // Handle optional technician_name
        if let techNameValue = try? container.decode(String.self, forKey: .technician_name), !techNameValue.isEmpty {
            technician_name = techNameValue
        } else {
            technician_name = nil
        }
        
        // Handle optional image_url
        if let imageValue = try? container.decode(String.self, forKey: .image_url), !imageValue.isEmpty {
            image_url = imageValue
        } else {
            image_url = nil
        }
        
        // ✅ FIXED: Handle status with smart fallback based on technician assignment
        if let statusValue = try? container.decode(String.self, forKey: .status), !statusValue.isEmpty {
            status = statusValue
        } else {
            // If no status is set, check if technician is assigned
            // If technician exists → "Assigned", otherwise → "In Progress"
            if technician_id != nil || technician_name != nil {
                status = "Assigned"
            } else {
                status = "In Progress"
            }
        }
    }
    
    // Custom encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(ticket_id, forKey: .ticket_id)
        try container.encode(description, forKey: .description)
        try container.encode(campus, forKey: .campus)
        try container.encode(due, forKey: .due)
        try container.encode(status, forKey: .status)
        try container.encode(priority, forKey: .priority)
        
        try container.encodeIfPresent(technician_id, forKey: .technician_id)
        try container.encodeIfPresent(technician, forKey: .technician)
        try container.encodeIfPresent(technician_name, forKey: .technician_name)
        try container.encodeIfPresent(image_url, forKey: .image_url)
    }
}

// MARK: - Helper Extensions
extension Ticket {
    
    // Get the technician name, with fallback logic
    var displayTechnicianName: String {
        if let name = technician_name, !name.isEmpty {
            return name
        } else if let tech = technician, !tech.isEmpty {
            return tech
        } else {
            return "Unassigned"
        }
    }
    
    // Format due date for display
    var formattedDueDate: String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: due) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM dd, HH:mm"
            return displayFormatter.string(from: date)
        }
        return due
    }
    
    // Calculate days remaining
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
    
    // Get days remaining text
    var daysRemainingText: String {
        let days = daysRemaining
        
        if days < 0 {
            return "\(abs(days)) days overdue"
        } else if days == 0 {
            return "Due today"
        } else if days == 1 {
            return "1 day left"
        } else {
            return "\(days) days left"
        }
    }
    
    // Check if overdue
    var isOverdue: Bool {
        return daysRemaining < 0
    }
    
    // Priority color
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
    
    // Status color
    var statusColor: UIColor {
        switch status.lowercased() {
        case "completed", "resolved", "done":
            return UIColor(red: 52/255, green: 199/255, blue: 89/255, alpha: 1) // Green
        case "in progress", "assigned":
            return UIColor(red: 255/255, green: 149/255, blue: 0/255, alpha: 1) // Orange
        case "pending", "new", "open":
            return UIColor(red: 255/255, green: 59/255, blue: 48/255, alpha: 1) // Red
        default:
            return .systemGray
        }
    }
    
    // Card accent color (left stripe)
    var accentColor: UIColor {
        // Alternate between blue and orange based on ticket_id
        return ticket_id % 2 == 0 ?
            UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1) :
            UIColor(red: 255/255, green: 162/255, blue: 19/255, alpha: 1)
    }
}
