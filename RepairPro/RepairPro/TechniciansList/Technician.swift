//
//  Technician.swift
//  RepairPro
//
//  Created by BP-36-212-19 on 29/12/2025.
//


//
//  Technician.swift
//  RepairPro
//
//  Model for Technician data
//

import Foundation

struct Technician {
    let id: Int
    let name: String
}

// MARK: - Protocol for communicating selection back to Edittickets
protocol TechnicianPickerDelegate: AnyObject {
    func didSelectTechnician(_ technician: Technician)
}
