//
//  Feedback.swift
//  Data model for user feedback submissions - FLEXIBLE VERSION
//

import Foundation
import FirebaseFirestore

struct Feedback: Codable, Identifiable {
    @DocumentID var id: String?
    
    let feedback_id: Int
    let user_id: String
    let user_name: String
    let category: String           // Any string now
    let title: String
    let description: String
    let rating: Int               // 1-5 stars
    let date_submitted: String    // Any date format
    var status: String            // Any string now
    
    // All optional fields
    var user_email: String?
    var admin_response: String?
    var response_date: String?
    var priority: String?
    let campus: String?
    let image_urls: [String]?
    var tags: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case feedback_id
        case user_id
        case user_name
        case user_email
        case category
        case title
        case description
        case rating
        case date_submitted
        case status
        case admin_response
        case response_date
        case priority
        case campus
        case image_urls
        case tags
    }
}

// MARK: - Helper Extensions
extension Feedback {
    var formattedDate: String {
        // Try to parse ISO8601 format
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: date_submitted) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM dd, yyyy 'at' HH:mm"
            return displayFormatter.string(from: date)
        }
        
        // If not ISO8601, just return as-is
        return date_submitted
    }
    
    var timeAgo: String {
        let formatter = ISO8601DateFormatter()
        guard let submittedDate = formatter.date(from: date_submitted) else {
            return "Recently"
        }
        
        let now = Date()
        let components = Calendar.current.dateComponents(
            [.day, .hour, .minute],
            from: submittedDate,
            to: now
        )
        
        if let days = components.day, days > 0 {
            return "\(days) day\(days == 1 ? "" : "s") ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else {
            return "Just now"
        }
    }
    
    var hasResponse: Bool {
        return admin_response != nil && !(admin_response?.isEmpty ?? true)
    }
    
    var categoryEmoji: String {
        // Map any category to an emoji
        let lowercased = category.lowercased()
        
        if lowercased.contains("complaint") || lowercased.contains("issue") || lowercased.contains("problem") {
            return "⚠️"
        } else if lowercased.contains("suggest") || lowercased.contains("idea") || lowercased.contains("feature") {
            return "💡"
        } else if lowercased.contains("bug") || lowercased.contains("error") || lowercased.contains("crash") {
            return "🐛"
        } else if lowercased.contains("good") || lowercased.contains("great") || lowercased.contains("nice") || lowercased.contains("love") {
            return "😊"
        } else {
            return "💬"
        }
    }
    
    var priorityColor: UIColor {
        guard let priority = priority else { return .systemGray }
        
        switch priority.lowercased() {
        case "high", "urgent", "critical":
            return .systemRed
        case "medium", "normal":
            return .systemOrange
        case "low":
            return .systemGreen
        default:
            return .systemGray
        }
    }
    
    var safeRating: Int {
        // Ensure rating is between 1-5
        return min(max(rating, 1), 5)
    }
}
