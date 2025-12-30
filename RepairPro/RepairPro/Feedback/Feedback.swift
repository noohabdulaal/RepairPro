//
//  Feedback.swift
//  Modern data model for user feedback submissions - Ticket Style
//

import Foundation
import FirebaseFirestore
import UIKit

struct Feedback: Codable, Identifiable {
    @DocumentID var id: String?
    
    let feedback_id: Int
    let user_id: String
    let user_name: String
    let category: String
    let title: String
    let description: String
    let rating: Int               // 1-5 stars
    let date_submitted: String
    var status: String
    
    // Optional fields
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
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: date_submitted) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMMM dd, yyyy"
            return displayFormatter.string(from: date)
        }
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
            return "\(days)d ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "Now"
        }
    }
    
    var hasResponse: Bool {
        return admin_response != nil && !(admin_response?.isEmpty ?? true)
    }
    
    // MARK: - Ticket Style Colors with #00476F
    var categoryColor: UIColor {
        let lowercased = category.lowercased()
        
        if lowercased.contains("complaint") || lowercased.contains("issue") || lowercased.contains("problem") {
            return UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1) // #00476F Dark Blue
        } else if lowercased.contains("suggest") || lowercased.contains("idea") || lowercased.contains("feature") {
            return UIColor(red: 52/255, green: 199/255, blue: 89/255, alpha: 1) // Green
        } else if lowercased.contains("bug") || lowercased.contains("error") || lowercased.contains("crash") {
            return UIColor(red: 255/255, green: 149/255, blue: 0/255, alpha: 1) // Orange
        } else if lowercased.contains("praise") || lowercased.contains("compliment") || lowercased.contains("positive") {
            return UIColor(red: 52/255, green: 199/255, blue: 89/255, alpha: 1) // Green
        } else {
            return UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1) // Default #00476F
        }
    }
    
    var statusColor: UIColor {
        let lowercased = status.lowercased()
        
        if lowercased.contains("complete") || lowercased.contains("resolve") || lowercased.contains("done") {
            return UIColor(red: 52/255, green: 199/255, blue: 89/255, alpha: 1) // Green
        } else if lowercased.contains("progress") || lowercased.contains("review") || lowercased.contains("investigating") {
            return UIColor(red: 255/255, green: 149/255, blue: 0/255, alpha: 1) // Orange
        } else if lowercased.contains("pending") || lowercased.contains("new") || lowercased.contains("submitted") {
            return UIColor(red: 255/255, green: 59/255, blue: 48/255, alpha: 1) // Red
        } else {
            return .systemGray
        }
    }
    
    var priorityColor: UIColor {
        guard let priority = priority else { return .systemGray }
        
        switch priority.lowercased() {
        case "high", "urgent", "critical":
            return UIColor(red: 255/255, green: 59/255, blue: 48/255, alpha: 1) // Red
        case "medium", "normal":
            return UIColor(red: 255/255, green: 149/255, blue: 0/255, alpha: 1) // Orange
        case "low":
            return UIColor(red: 52/255, green: 199/255, blue: 89/255, alpha: 1) // Green
        default:
            return .systemGray
        }
    }
    
    var safeRating: Int {
        return min(max(rating, 1), 5)
    }
    
    var ratingText: String {
        return "\(safeRating)/5"
    }
}
