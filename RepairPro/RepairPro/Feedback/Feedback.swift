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
    
    // Custom decoding to handle malformed field names and empty values
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode @DocumentID separately
        _id = try DocumentID(from: decoder)
        
        // Decode required fields
        feedback_id = try container.decode(Int.self, forKey: .feedback_id)
        user_id = try container.decode(String.self, forKey: .user_id)
        user_name = try container.decode(String.self, forKey: .user_name)
        
        // Handle category with fallback for empty strings
        let categoryValue = try container.decode(String.self, forKey: .category)
        category = categoryValue.isEmpty ? "Uncategorized" : categoryValue
        
        // Handle description with fallback for empty/null values
        if let descValue = try? container.decode(String.self, forKey: .description), !descValue.isEmpty {
            description = descValue
        } else {
            description = "No description provided"
        }
        
        rating = try container.decode(Int.self, forKey: .rating)
        
        // Handle date_submitted - could be string or timestamp
        if let dateString = try? container.decode(String.self, forKey: .date_submitted) {
            date_submitted = dateString
        } else if let timestamp = try? container.decode(Timestamp.self, forKey: .date_submitted) {
            let formatter = ISO8601DateFormatter()
            date_submitted = formatter.string(from: timestamp.dateValue())
        } else {
            // Fallback to current date
            let formatter = ISO8601DateFormatter()
            date_submitted = formatter.string(from: Date())
        }
        
        status = try container.decode(String.self, forKey: .status)
        
        // Handle title with fallback for malformed keys and spaces
        if let normalTitle = try? container.decode(String.self, forKey: .title), !normalTitle.isEmpty {
            title = normalTitle
        } else {
            // Try to find any key that contains "title"
            let allKeys = container.allKeys
            var foundTitle: String?
            
            for key in allKeys {
                if key.stringValue.contains("title") {
                    if let value = try? container.decode(String.self, forKey: key), !value.isEmpty {
                        foundTitle = value
                        print("⚠️ Found malformed title key: '\(key.stringValue)' with value: '\(value)'")
                        break
                    }
                }
            }
            
            title = foundTitle ?? "Untitled"
            
            if foundTitle == nil {
                print("⚠️ No title field found, using 'Untitled' as default")
            }
        }
        
        // Decode optional fields
        user_email = try? container.decode(String.self, forKey: .user_email)
        admin_response = try? container.decode(String.self, forKey: .admin_response)
        response_date = try? container.decode(String.self, forKey: .response_date)
        priority = try? container.decode(String.self, forKey: .priority)
        campus = try? container.decode(String.self, forKey: .campus)
        image_urls = try? container.decode([String].self, forKey: .image_urls)
        tags = try? container.decode([String].self, forKey: .tags)
    }
    
    // Custom encoding to ensure proper field names
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(feedback_id, forKey: .feedback_id)
        try container.encode(user_id, forKey: .user_id)
        try container.encode(user_name, forKey: .user_name)
        try container.encode(category, forKey: .category)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(rating, forKey: .rating)
        try container.encode(date_submitted, forKey: .date_submitted)
        try container.encode(status, forKey: .status)
        
        try container.encodeIfPresent(user_email, forKey: .user_email)
        try container.encodeIfPresent(admin_response, forKey: .admin_response)
        try container.encodeIfPresent(response_date, forKey: .response_date)
        try container.encodeIfPresent(priority, forKey: .priority)
        try container.encodeIfPresent(campus, forKey: .campus)
        try container.encodeIfPresent(image_urls, forKey: .image_urls)
        try container.encodeIfPresent(tags, forKey: .tags)
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
    
    // MARK: - Random Color for Ticket (Dark Blue or Orange)
    var categoryColor: UIColor {
        // Use feedback_id to consistently assign color
        let colors: [UIColor] = [
            UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1),    // #00476F Dark Blue
            UIColor(red: 255/255, green: 162/255, blue: 19/255, alpha: 1)   // #FFA213 Orange
        ]
        
        // Use modulo to alternate between the two colors based on feedback_id
        return colors[feedback_id % 2]
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
