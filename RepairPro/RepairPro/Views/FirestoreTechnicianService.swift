//
//  FirestoreTechnicianService.swift
//  RepairPro
//
//  Created by ec2-user on 04/01/2026.
//

import Foundation
import FirebaseFirestore

final class FirestoreTechnicianService {

    static let shared = FirestoreTechnicianService()
    private let db = Firestore.firestore()

    private let collection = "technicians"

    func fetchTechnicians(completion: @escaping ([TechnicianListViewController.Technician]) -> Void) {
        db.collection(collection).getDocuments { snapshot, error in
            guard let docs = snapshot?.documents else {
                completion([])
                return
            }

            let technicians = docs.compactMap { doc -> TechnicianListViewController.Technician? in
                let data = doc.data()
                return TechnicianListViewController.Technician(
                    id: UUID(uuidString: doc.documentID) ?? UUID(),
                    name: data["name"] as? String ?? "",
                    department: data["department"] as? String ?? "",
                    phone: data["phone"] as? String ?? "",
                    username: data["username"] as? String ?? ""
                )
            }

            completion(technicians)
        }
    }

    func addTechnician(_ tech: TechnicianListViewController.Technician) {
        db.collection(collection).document(tech.id.uuidString).setData([
            "name": tech.name,
            "department": tech.department,
            "phone": tech.phone,
            "username": tech.username
        ])
    }

    func updateTechnician(_ tech: TechnicianListViewController.Technician) {
        db.collection(collection).document(tech.id.uuidString).updateData([
            "name": tech.name,
            "department": tech.department,
            "phone": tech.phone
        ])
    }

    func deleteTechnician(id: UUID) {
        db.collection(collection).document(id.uuidString).delete()
    }
}
