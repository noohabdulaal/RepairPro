//
//  Category.swift
//  RepairPro
//
//  Helper model for ticket categories
//  Developer: Noof Abdullah [202204310]
//

import Foundation
import FirebaseFirestore

// MARK: - Category Model
struct Category: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case isActive = "is_active"
    }
    
    init(name: String, isActive: Bool = true) {
        self.name = name
        self.isActive = isActive
    }
}

// MARK: - Category Operations
extension Category {
    
    private static let db = Firestore.firestore()
    
    // MARK: - READ CATEGORIES
    static func fetchAll(completion: @escaping (Result<[Category], Error>) -> Void) {
        db.collection("categories")
            .whereField("is_active", isEqualTo: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let categories = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: Category.self)
                } ?? []
                
                completion(.success(categories))
            }
    }
    
    static func fetchCategoryNames(completion: @escaping (Result<[String], Error>) -> Void) {
        fetchAll { result in
            switch result {
            case .success(let categories):
                let names = categories.map { $0.name }
                completion(.success(names))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
