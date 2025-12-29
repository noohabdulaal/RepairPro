//
//  Ticket.swift (UPDATED)
//  Add this to the bottom of your TicketViewList.swift file
//  OR replace your existing Ticket struct
//

import Foundation

struct Ticket: Codable {
    let ticket_id: Int
    let due: String
    let description: String
    var status: String
    let campus: String
    let image_url: String?
    let priority: String?
    
    // Technician fields
    var technician_name: String?
    var technician_id: Int?
    
    // ✅ NEW: Category field (ADD THIS)
    var category: String?
}
