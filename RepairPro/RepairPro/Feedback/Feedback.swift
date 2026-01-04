//
//  Feedback.swift
//  Modern data model for user feedback submissions - Ticket Style
//  FIXED VERSION - Handles empty strings and trims whitespace
//

import Foundation
import FirebaseFirestore
import UIKit

// MARK: - Feedback Model
// This struct represents a single feedback/complaint submitted by a user
// It conforms to Codable (can be converted to/from JSON) and Identifiable (has unique ID)
struct Feedback: Codable, Identifiable {
    // Firestore document ID - automatically managed by Firebase
    @DocumentID var id: String?
    
    // MARK: - Required Fields (must exist in database)
    let feedback_id: Int          // Unique number for this feedback
    let user_id: String           // ID of the user who submitted it
    let user_name: String         // Name of the user
    let category: String          // Category (e.g., "Maintenance", "Complaint")
    let title: String             // Short title/subject
    let description: String       // Full description of the issue
    let rating: Int               // User rating (1-5 stars)
    let date_submitted: String    // When it was submitted (ISO8601 format)
    var status: String            // Current status (e.g., "Pending", "In Progress")
    
    // MARK: - Optional Fields (may or may not exist)
    var user_email: String?       // User's email address
    var admin_response: String?   // Admin's reply/response
    var response_date: String?    // When admin responded
    var priority: String?         // Priority level (High, Medium, Low)
    let campus: String?           // Which campus/location
    let image_urls: [String]?     // Array of image URLs attached to feedback
    var tags: [String]?           // Optional tags for categorization
    
    // MARK: - Coding Keys
    // Maps Swift property names to Firebase field names
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
    
    // MARK: - Custom Decoder
    // This handles loading data from Firebase and dealing with missing/malformed data
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Get the Firestore document ID
        _id = try DocumentID(from: decoder)
        
        // Decode basic required fields (must exist or will crash)
        feedback_id = try container.decode(Int.self, forKey: .feedback_id)
        user_id = try container.decode(String.self, forKey: .user_id)
        user_name = try container.decode(String.self, forKey: .user_name)
        
        // Handle category - if empty string, use "Uncategorized" as default
        let categoryValue = try container.decode(String.self, forKey: .category)
        let trimmedCategory = categoryValue.trimmingCharacters(in: .whitespaces)
        category = trimmedCategory.isEmpty ? "Uncategorized" : trimmedCategory
        
        // Handle description with smart validation
        // Checks if description is empty, just dots (...), "none", or "n/a"
        if let descValue = try? container.decode(String.self, forKey: .description) {
            let trimmed = descValue.trimmingCharacters(in: .whitespaces)
            // Check if description is actually useful text
            let isValidDescription = !trimmed.isEmpty &&
                                   !trimmed.allSatisfy({ $0 == "." }) &&  // Not just dots
                                   trimmed.lowercased() != "none" &&
                                   trimmed.lowercased() != "n/a"
            
            // Use the description if valid, otherwise use placeholder
            description = isValidDescription ? trimmed : "No description provided"
        } else {
            description = "No description provided"
        }
        
        // Get the rating (1-5 stars)
        rating = try container.decode(Int.self, forKey: .rating)
        
        // Handle date_submitted - could be a string OR a Firebase Timestamp
        if let dateString = try? container.decode(String.self, forKey: .date_submitted) {
            // It's already a string, use it directly
            date_submitted = dateString
        } else if let timestamp = try? container.decode(Timestamp.self, forKey: .date_submitted) {
            // It's a Firebase Timestamp, convert to ISO8601 string
            let formatter = ISO8601DateFormatter()
            date_submitted = formatter.string(from: timestamp.dateValue())
        } else {
            // No date found, use current date as fallback
            let formatter = ISO8601DateFormatter()
            date_submitted = formatter.string(from: Date())
        }
        
        // ✅ FIX: Handle status - if empty string, use "Pending" as default
        let statusValue = try container.decode(String.self, forKey: .status)
        let trimmedStatus = statusValue.trimmingCharacters(in: .whitespaces)
        status = trimmedStatus.isEmpty ? "Pending" : trimmedStatus
        
        // ✅ FIX: Handle title with trimming and special logic for malformed database keys
        if let normalTitle = try? container.decode(String.self, forKey: .title) {
            let trimmed = normalTitle.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                // Normal title found and not empty after trimming
                title = trimmed
            } else {
                // Title is empty after trimming, search for malformed keys
                let allKeys = container.allKeys
                var foundTitle: String?
                
                // Loop through all keys looking for anything containing "title"
                for key in allKeys {
                    if key.stringValue.contains("title") {
                        if let value = try? container.decode(String.self, forKey: key) {
                            let trimmedValue = value.trimmingCharacters(in: .whitespaces)
                            if !trimmedValue.isEmpty {
                                foundTitle = trimmedValue
                                print("⚠️ Found malformed title key: '\(key.stringValue)' with value: '\(trimmedValue)'")
                                break
                            }
                        }
                    }
                }
                
                // Use found title or "Untitled" as last resort
                title = foundTitle ?? "Untitled"
                
                if foundTitle == nil {
                    print("⚠️ No title field found, using 'Untitled' as default")
                }
            }
        } else {
            // Normal title decode failed, search for malformed keys
            let allKeys = container.allKeys
            var foundTitle: String?
            
            // Loop through all keys looking for anything containing "title"
            for key in allKeys {
                if key.stringValue.contains("title") {
                    if let value = try? container.decode(String.self, forKey: key) {
                        let trimmedValue = value.trimmingCharacters(in: .whitespaces)
                        if !trimmedValue.isEmpty {
                            foundTitle = trimmedValue
                            print("⚠️ Found malformed title key: '\(key.stringValue)' with value: '\(trimmedValue)'")
                            break
                        }
                    }
                }
            }
            
            // Use found title or "Untitled" as last resort
            title = foundTitle ?? "Untitled"
            
            if foundTitle == nil {
                print("⚠️ No title field found, using 'Untitled' as default")
            }
        }
        
        // Decode all optional fields (won't crash if missing)
        user_email = try? container.decode(String.self, forKey: .user_email)
        
        // ✅ FIX: Trim admin_response if it exists
        if let adminResp = try? container.decode(String.self, forKey: .admin_response) {
            let trimmed = adminResp.trimmingCharacters(in: .whitespaces)
            admin_response = trimmed.isEmpty ? nil : trimmed
        } else {
            admin_response = nil
        }
        
        response_date = try? container.decode(String.self, forKey: .response_date)
        
        // ✅ FIX: Trim priority if it exists
        if let priorityValue = try? container.decode(String.self, forKey: .priority) {
            let trimmed = priorityValue.trimmingCharacters(in: .whitespaces)
            priority = trimmed.isEmpty ? nil : trimmed
        } else {
            priority = nil
        }
        
        campus = try? container.decode(String.self, forKey: .campus)
        image_urls = try? container.decode([String].self, forKey: .image_urls)
        tags = try? container.decode([String].self, forKey: .tags)
    }
    
    // MARK: - Custom Encoder
    // This handles saving data back to Firebase with proper field names
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode all required fields
        try container.encode(feedback_id, forKey: .feedback_id)
        try container.encode(user_id, forKey: .user_id)
        try container.encode(user_name, forKey: .user_name)
        try container.encode(category, forKey: .category)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(rating, forKey: .rating)
        try container.encode(date_submitted, forKey: .date_submitted)
        try container.encode(status, forKey: .status)
        
        // Encode optional fields only if they have values
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
// Extra computed properties to make working with Feedback easier
extension Feedback {
    
    // MARK: - Formatted Date
    // Converts "2025-01-03T15:30:00Z" to "January 03, 2025"
    var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: date_submitted) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMMM dd, yyyy"
            return displayFormatter.string(from: date)
        }
        // If parsing fails, return the raw date string
        return date_submitted
    }
    
    // MARK: - Time Ago
    // Shows how long ago the feedback was submitted (e.g., "2d ago", "5h ago")
    var timeAgo: String {
        let formatter = ISO8601DateFormatter()
        guard let submittedDate = formatter.date(from: date_submitted) else {
            return "Recently"
        }
        
        let now = Date()
        // Calculate the difference between submission time and now
        let components = Calendar.current.dateComponents(
            [.day, .hour, .minute],
            from: submittedDate,
            to: now
        )
        
        // Return the largest meaningful unit
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
    
    // MARK: - Has Response Check
    // Returns true if admin has responded to this feedback
    var hasResponse: Bool {
        return admin_response != nil && !(admin_response?.isEmpty ?? true)
    }
    
    // MARK: - Category Color
    // Assigns a color based on feedback ID (alternates between blue and orange)
    var categoryColor: UIColor {
        // Two possible colors
        let colors: [UIColor] = [
            UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1),    // #00476F Dark Blue
            UIColor(red: 255/255, green: 162/255, blue: 19/255, alpha: 1)   // #FFA213 Orange
        ]
        
        // Use modulo (%) to alternate colors: even IDs get blue, odd IDs get orange
        return colors[feedback_id % 2]
    }
    
    // MARK: - Status Color
    // Returns color based on current status of the feedback
    var statusColor: UIColor {
        let lowercased = status.lowercased()
        
        // Check status and return appropriate color
        if lowercased.contains("complete") || lowercased.contains("resolve") || lowercased.contains("done") {
            return UIColor(red: 52/255, green: 199/255, blue: 89/255, alpha: 1) // Green (finished)
        } else if lowercased.contains("progress") || lowercased.contains("review") || lowercased.contains("investigating") {
            return UIColor(red: 255/255, green: 149/255, blue: 0/255, alpha: 1) // Orange (in progress)
        } else if lowercased.contains("pending") || lowercased.contains("new") || lowercased.contains("submitted") {
            return UIColor(red: 255/255, green: 59/255, blue: 48/255, alpha: 1) // Red (new/waiting)
        } else {
            return .systemGray // Default gray for unknown status
        }
    }
    
    // MARK: - Priority Color
    // Returns color based on priority level (High=Red, Medium=Orange, Low=Green)
    var priorityColor: UIColor {
        guard let priority = priority else { return .systemGray }
        
        switch priority.lowercased() {
        case "high", "urgent", "critical":
            return UIColor(red: 255/255, green: 59/255, blue: 48/255, alpha: 1) // Red (urgent!)
        case "medium", "normal":
            return UIColor(red: 255/255, green: 149/255, blue: 0/255, alpha: 1) // Orange (moderate)
        case "low":
            return UIColor(red: 52/255, green: 199/255, blue: 89/255, alpha: 1) // Green (can wait)
        default:
            return .systemGray
        }
    }
    
    // MARK: - Safe Rating
    // Ensures rating is always between 1 and 5 (in case of bad data)
    var safeRating: Int {
        return min(max(rating, 1), 5)
    }
    
    // MARK: - Rating Text
    // Returns rating as text like "4/5"
    var ratingText: String {
        return "\(safeRating)/5"
    }
}
