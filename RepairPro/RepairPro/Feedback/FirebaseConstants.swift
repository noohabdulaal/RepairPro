//
//  FirebaseConstants.swift
//  Best practice: Centralize all Firebase collection and field names
//  This prevents typos and makes updates easier
//

import Foundation

// MARK: - Firestore Collection Names
/// All Firestore collection names used in the app
struct FirebaseCollections {
    /// Main feedback/complaints collection
    /// IMPORTANT: Firebase collection name is "Feedback" (capital F), not "feedback"
    static let feedback = "Feedback"
    
    // Add other collections as your app grows:
    // static let users = "Users"
    // static let settings = "Settings"
    // static let notifications = "Notifications"
}

// MARK: - Firestore Field Names
/// All Firestore field names organized by collection
struct FirebaseFields {
    
    /// Field names for the Feedback collection
    struct Feedback {
        static let feedbackId = "feedback_id"
        static let userId = "user_id"
        static let userName = "user_name"
        static let userEmail = "user_email"
        static let category = "category"
        static let title = "title"
        static let description = "description"
        static let rating = "rating"
        static let dateSubmitted = "date_submitted"
        static let status = "status"
        static let adminResponse = "admin_response"
        static let responseDate = "response_date"
        static let priority = "priority"
        static let campus = "campus"
        static let imageUrls = "image_urls"
        static let tags = "tags"
    }
    
    // Add field names for other collections:
    // struct Users {
    //     static let userId = "user_id"
    //     static let email = "email"
    //     static let name = "name"
    // }
}

// MARK: - Usage Examples
/*
 
 Instead of hardcoding strings:
 ❌ db.collection("feedback").getDocuments()
 ❌ .whereField("status", isEqualTo: "Pending")
 
 Use the constants:
 ✅ db.collection(FirebaseCollections.feedback).getDocuments()
 ✅ .whereField(FirebaseFields.Feedback.status, isEqualTo: "Pending")
 
 Benefits:
 1. No typos (autocomplete works)
 2. Change in one place if needed
 3. Compile-time checking
 4. Easy to see all Firebase structure
 
 Example queries:
 
 // Get all feedback
 db.collection(FirebaseCollections.feedback)
     .getDocuments { (snapshot, error) in
         // ...
     }
 
 // Get pending feedback only
 db.collection(FirebaseCollections.feedback)
     .whereField(FirebaseFields.Feedback.status, isEqualTo: "Pending")
     .getDocuments { (snapshot, error) in
         // ...
     }
 
 // Get specific document
 db.collection(FirebaseCollections.feedback)
     .document(documentId)
     .getDocument { (snapshot, error) in
         // ...
     }
 
 // Update a field
 db.collection(FirebaseCollections.feedback)
     .document(documentId)
     .updateData([
         FirebaseFields.Feedback.status: "Completed",
         FirebaseFields.Feedback.adminResponse: "Fixed!"
     ])
 
 // Query with multiple conditions
 db.collection(FirebaseCollections.feedback)
     .whereField(FirebaseFields.Feedback.priority, isEqualTo: "High")
     .whereField(FirebaseFields.Feedback.status, isEqualTo: "Pending")
     .order(by: FirebaseFields.Feedback.dateSubmitted, descending: true)
     .getDocuments { (snapshot, error) in
         // ...
     }
 
 */
