//
//  Feedback.swift
//  RepairPro
//
//  Feature 4: Request Feedback
//  Developer: Noof Abdullah [202204310]
//

import Foundation
import FirebaseFirestore

// MARK: - Feedback Model
struct Feedback: Codable, Identifiable {
    @DocumentID var id: String?
    var ticketId: String
    var userId: String
    var userName: String
    var rating: Int  // 1-5 stars
    var comment: String?
    var category: String
    var dateSubmitted: Timestamp
    var technicianId: String
    var technicianName: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case ticketId = "ticket_id"
        case userId = "user_id"
        case userName = "user_name"
        case rating
        case comment
        case category
        case dateSubmitted = "date_submitted"
        case technicianId = "technician_id"
        case technicianName = "technician_name"
    }
    
    // MARK: - Initializer
    init(ticketId: String,
         userId: String,
         userName: String,
         rating: Int,
         comment: String? = nil,
         category: String,
         technicianId: String,
         technicianName: String) {
        
        self.ticketId = ticketId
        self.userId = userId
        self.userName = userName
        self.rating = max(1, min(5, rating))  // Ensure 1-5
        self.comment = comment
        self.category = category
        self.dateSubmitted = Timestamp(date: Date())
        self.technicianId = technicianId
        self.technicianName = technicianName
    }
}

// MARK: - Feedback Extensions
extension Feedback {
    var formattedDate: String {
        let date = dateSubmitted.dateValue()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    var ratingStars: String {
        return String(repeating: "⭐️", count: rating)
    }
    
    var status: String {
        switch rating {
        case 4...5: return "good"
        case 3: return "average"
        default: return "poor"
        }
    }
}

// MARK: - Feedback CRUD Operations
extension Feedback {
    
    private static let db = Firestore.firestore()
    
    // MARK: - CREATE FEEDBACK
    static func submit(
        ticketId: String,
        userId: String,
        userName: String,
        rating: Int,
        comment: String?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // Step 1: Get ticket details
        db.collection("tickets").document(ticketId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let ticketData = snapshot?.data(),
                  let status = ticketData["status"] as? String,
                  status == "Done",
                  let technicianId = ticketData["technician_id"] as? String,
                  let technicianName = ticketData["technician_name"] as? String,
                  let category = ticketData["category"] as? String else {
                completion(.failure(NSError(domain: "Feedback", code: 403,
                                           userInfo: [NSLocalizedDescriptionKey: "Cannot submit feedback for this ticket"])))
                return
            }
            
            // Step 2: Create feedback
            let feedback = Feedback(
                ticketId: ticketId,
                userId: userId,
                userName: userName,
                rating: rating,
                comment: comment,
                category: category,
                technicianId: technicianId,
                technicianName: technicianName
            )
            
            // Step 3: Save to Firestore
            do {
                try db.collection("feedback").addDocument(from: feedback) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success("Feedback submitted successfully"))
                    }
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - READ FEEDBACK
    static func checkIfFeedbackExists(
        ticketId: String,
        userId: String,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        db.collection("feedback")
            .whereField("ticket_id", isEqualTo: ticketId)
            .whereField("user_id", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let exists = !(snapshot?.documents.isEmpty ?? true)
                completion(.success(exists))
            }
    }
    
    static func fetchFeedbackForTicket(
        ticketId: String,
        completion: @escaping (Result<Feedback?, Error>) -> Void
    ) {
        db.collection("feedback")
            .whereField("ticket_id", isEqualTo: ticketId)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let feedback = snapshot?.documents.first.flatMap { doc in
                    try? doc.data(as: Feedback.self)
                }
                
                completion(.success(feedback))
            }
    }
}
