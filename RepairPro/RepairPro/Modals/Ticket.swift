//
//  Ticket.swift
//  RepairPro
//
//  Feature 3 & 4: Create & Manage Tickets
//  Developer: Noof Abdullah [202204310]
//

import Foundation
import FirebaseFirestore
import FirebaseStorage

// MARK: - Ticket Model
struct Ticket: Codable, Identifiable {
    @DocumentID var id: String?
    var ticketNumber: Int
    var title: String
    var description: String
    var category: String
    var campus: String
    var building: String
    var roomNumber: String
    var imageUrl: String?
    var status: TicketStatus
    var priority: TicketPriority
    var userId: String
    var userName: String
    var technicianId: String?
    var technicianName: String?
    var createdAt: Timestamp
    var updatedAt: Timestamp
    var completedAt: Timestamp?
    var history: [TicketHistory]
    
    enum CodingKeys: String, CodingKey {
        case id
        case ticketNumber = "ticket_number"
        case title
        case description
        case category
        case campus
        case building
        case roomNumber = "room_number"
        case imageUrl = "image_url"
        case status
        case priority
        case userId = "user_id"
        case userName = "user_name"
        case technicianId = "technician_id"
        case technicianName = "technician_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case completedAt = "completed_at"
        case history
    }
    
    // MARK: - Initializer
    init(ticketNumber: Int,
         title: String,
         description: String,
         category: String,
         campus: String,
         building: String,
         roomNumber: String,
         imageUrl: String? = nil,
         userId: String,
         userName: String) {
        
        self.ticketNumber = ticketNumber
        self.title = title
        self.description = description
        self.category = category
        self.campus = campus
        self.building = building
        self.roomNumber = roomNumber
        self.imageUrl = imageUrl
        self.status = .new
        self.priority = .low
        self.userId = userId
        self.userName = userName
        self.createdAt = Timestamp(date: Date())
        self.updatedAt = Timestamp(date: Date())
        self.history = [TicketHistory(action: "Created", user: userName, details: "Ticket created")]
    }
}

// MARK: - Ticket Status
enum TicketStatus: String, Codable, CaseIterable {
    case new = "New"
    case assigned = "Assigned"
    case inProgress = "In Progress"
    case done = "Done"
    case cancelled = "Cancelled"
}

// MARK: - Ticket Priority
enum TicketPriority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

// MARK: - Ticket History
struct TicketHistory: Codable {
    var action: String
    var timestamp: Timestamp
    var user: String
    var details: String
    
    init(action: String, user: String, details: String) {
        self.action = action
        self.timestamp = Timestamp(date: Date())
        self.user = user
        self.details = details
    }
}

// MARK: - Ticket Extensions
extension Ticket {
    var formattedCreatedDate: String {
        let date = createdAt.dateValue()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    var formattedCreatedDateTime: String {
        let date = createdAt.dateValue()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy, h:mm a"
        return formatter.string(from: date)
    }
    
    var isEditable: Bool {
        return status == .new
    }
    
    var isCancellable: Bool {
        return status == .new
    }
    
    var canProvideFeedback: Bool {
        return status == .done
    }
    
    var fullLocation: String {
        return "\(campus), \(building), Room \(roomNumber)"
    }
}

// MARK: - Ticket CRUD Operations
extension Ticket {
    
    private static let db = Firestore.firestore()
    private static let storage = Storage.storage()
    
    // MARK: - CREATE TICKET
    static func create(
        title: String,
        description: String,
        category: String,
        campus: String,
        building: String,
        roomNumber: String,
        image: UIImage?,
        userId: String,
        userName: String,
        completion: @escaping (Result<(String, Int), Error>) -> Void
    ) {
        print("🎫 ===== CREATING TICKET =====")
        print("📝 Title: \(title)")
        print("📝 User: \(userName) (ID: \(userId))")
        print("📝 Category: \(category)")
        print("📝 Location: \(campus), \(building), Room \(roomNumber)")
        
        // Step 1: Get next ticket number
        print("📝 Step 1: Getting next ticket number...")
        getNextTicketNumber { result in
            switch result {
            case .success(let ticketNumber):
                print("✅ Got ticket number: \(ticketNumber)")
                
                // Step 2: Create ticket object
                print("📝 Step 2: Creating ticket object...")
                var ticket = Ticket(
                    ticketNumber: ticketNumber,
                    title: title,
                    description: description,
                    category: category,
                    campus: campus,
                    building: building,
                    roomNumber: roomNumber,
                    userId: userId,
                    userName: userName
                )
                
                // Step 3: Convert image to Base64 if exists
                if let image = image {
                    print("📝 Step 3: Converting image to Base64...")
                    if let base64String = convertImageToBase64(image) {
                        print("✅ Image converted to Base64 (length: \(base64String.count) chars)")
                        ticket.imageUrl = base64String
                    } else {
                        print("⚠️ Failed to convert image, saving without image...")
                    }
                }
                
                print("📝 Saving ticket to Firestore...")
                saveToFirestore(ticket, completion: completion)
                
            case .failure(let error):
                print("❌ Failed to get ticket number: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - READ TICKETS
    static func fetchCurrentTickets(
        userId: String,
        completion: @escaping (Result<[Ticket], Error>) -> Void
    ) {
        db.collection("tickets")
            .whereField("user_id", isEqualTo: userId)
            .whereField("status", in: ["New", "Assigned", "In Progress"])
            .order(by: "created_at", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let tickets = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: Ticket.self)
                } ?? []
                
                completion(.success(tickets))
            }
    }
    
    static func fetchPreviousTickets(
        userId: String,
        completion: @escaping (Result<[Ticket], Error>) -> Void
    ) {
        print("🔍 ===== FETCHING PREVIOUS TICKETS =====")
        print("📝 User ID: \(userId)")
        print("📝 Looking for ALL tickets (any status)")
        
        db.collection("tickets")
            .whereField("user_id", isEqualTo: userId)
            .order(by: "created_at", descending: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching previous tickets: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                print("📊 Raw documents found: \(snapshot?.documents.count ?? 0)")
                
                let tickets = snapshot?.documents.compactMap { doc -> Ticket? in
                    do {
                        let ticket = try doc.data(as: Ticket.self)
                        print("✅ Decoded ticket: #\(ticket.ticketNumber) - Status: \(ticket.status.rawValue)")
                        return ticket
                    } catch {
                        print("❌ Failed to decode ticket: \(error.localizedDescription)")
                        print("📄 Document data: \(doc.data())")
                        return nil
                    }
                } ?? []
                
                print("✅ Total previous tickets loaded: \(tickets.count)")
                completion(.success(tickets))
            }
    }
    
    static func fetchTicketById(
        ticketId: String,
        completion: @escaping (Result<Ticket, Error>) -> Void
    ) {
        db.collection("tickets").document(ticketId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let ticket = try? snapshot?.data(as: Ticket.self) else {
                completion(.failure(NSError(domain: "Ticket", code: 404, userInfo: [NSLocalizedDescriptionKey: "Ticket not found"])))
                return
            }
            
            completion(.success(ticket))
        }
    }
    
    // MARK: - UPDATE TICKET
    func update(
        title: String? = nil,
        description: String? = nil,
        category: String? = nil,
        roomNumber: String? = nil,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let ticketId = self.id else {
            completion(.failure(NSError(domain: "Ticket", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid ticket ID"])))
            return
        }
        
        guard self.isEditable else {
            completion(.failure(NSError(domain: "Ticket", code: 403, userInfo: [NSLocalizedDescriptionKey: "Ticket cannot be edited"])))
            return
        }
        
        var updateData: [String: Any] = [
            "updated_at": Timestamp(date: Date())
        ]
        
        if let title = title { updateData["title"] = title }
        if let description = description { updateData["description"] = description }
        if let category = category { updateData["category"] = category }
        if let roomNumber = roomNumber { updateData["room_number"] = roomNumber }
        
        // Add to history
        let historyEntry = TicketHistory(action: "Updated", user: self.userName, details: "Ticket details updated")
        var updatedHistory = self.history
        updatedHistory.append(historyEntry)
        
        do {
            let historyData = try updatedHistory.map { try Firestore.Encoder().encode($0) }
            updateData["history"] = historyData
        } catch {
            completion(.failure(error))
            return
        }
        
        Ticket.db.collection("tickets").document(ticketId).updateData(updateData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // MARK: - CANCEL TICKET
    func cancel(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let ticketId = self.id else {
            completion(.failure(NSError(domain: "Ticket", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid ticket ID"])))
            return
        }
        
        guard self.isCancellable else {
            completion(.failure(NSError(domain: "Ticket", code: 403, userInfo: [NSLocalizedDescriptionKey: "Only new tickets can be cancelled"])))
            return
        }
        
        let historyEntry = TicketHistory(action: "Cancelled", user: self.userName, details: "Ticket cancelled by user")
        var updatedHistory = self.history
        updatedHistory.append(historyEntry)
        
        do {
            let historyData = try updatedHistory.map { try Firestore.Encoder().encode($0) }
            
            let updateData: [String: Any] = [
                "status": TicketStatus.cancelled.rawValue,
                "updated_at": Timestamp(date: Date()),
                "completed_at": Timestamp(date: Date()),
                "history": historyData
            ]
            
            Ticket.db.collection("tickets").document(ticketId).updateData(updateData) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - Helper Methods
    private static func getNextTicketNumber(completion: @escaping (Result<Int, Error>) -> Void) {
        let counterRef = db.collection("app_settings").document("ticket_counter")
        
        print("📝 Getting next ticket number...")
        
        // First check if document exists
        counterRef.getDocument { snapshot, error in
            if let error = error {
                print("❌ Error checking ticket_counter: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if snapshot?.exists == false {
                print("⚠️ ticket_counter doesn't exist! Creating it now...")
                // Create the document first
                counterRef.setData(["current_value": 0]) { error in
                    if let error = error {
                        print("❌ Failed to create ticket_counter: \(error.localizedDescription)")
                        completion(.failure(error))
                        return
                    }
                    print("✅ ticket_counter created successfully")
                    // Now get the ticket number
                    self.performTicketNumberTransaction(counterRef: counterRef, completion: completion)
                }
            } else {
                // Document exists, proceed with transaction
                self.performTicketNumberTransaction(counterRef: counterRef, completion: completion)
            }
        }
    }
    
    private static func performTicketNumberTransaction(counterRef: DocumentReference, completion: @escaping (Result<Int, Error>) -> Void) {
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let counterDoc: DocumentSnapshot
            do {
                try counterDoc = transaction.getDocument(counterRef)
            } catch let fetchError as NSError {
                print("❌ Transaction error: \(fetchError.localizedDescription)")
                errorPointer?.pointee = fetchError
                return nil
            }
            
            let currentValue = counterDoc.data()?["current_value"] as? Int ?? 0
            let nextValue = currentValue + 1
            
            print("📝 Current ticket number: \(currentValue), Next: \(nextValue)")
            
            transaction.updateData(["current_value": nextValue], forDocument: counterRef)
            return nextValue
            
        }) { (result, error) in
            if let error = error {
                print("❌ Failed to get ticket number: \(error.localizedDescription)")
                completion(.failure(error))
            } else if let ticketNumber = result as? Int {
                print("✅ Got ticket number: \(ticketNumber)")
                completion(.success(ticketNumber))
            }
        }
    }
    
    // MARK: - Convert Image to Base64
    private static func convertImageToBase64(_ image: UIImage) -> String? {
        // Compress image to reduce size (important for Firestore)
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            return nil
        }
        
        // Convert to Base64
        let base64String = imageData.base64EncodedString()
        return "data:image/jpeg;base64,\(base64String)"
    }
    
    // MARK: - Convert Base64 to Image
    static func convertBase64ToImage(_ base64String: String) -> UIImage? {
        // Remove the data:image/jpeg;base64, prefix if present
        let base64 = base64String.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
        
        guard let imageData = Data(base64Encoded: base64) else {
            return nil
        }
        
        return UIImage(data: imageData)
    }
    
    private static func saveToFirestore(_ ticket: Ticket, completion: @escaping (Result<(String, Int), Error>) -> Void) {
        print("💾 Saving ticket to Firestore...")
        print("💾 Ticket data: #\(ticket.ticketNumber) - \(ticket.title)")
        
        do {
            let ticketRef = try db.collection("tickets").addDocument(from: ticket)
            
            print("✅ Ticket saved! Document ID: \(ticketRef.documentID)")
            completion(.success((ticketRef.documentID, ticket.ticketNumber)))
            
        } catch {
            print("❌ Failed to save ticket: \(error.localizedDescription)")
            print("❌ Error details: \(error)")
            completion(.failure(error))
        }
    }
}
