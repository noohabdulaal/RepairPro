//
//  Location.swift
//  RepairPro
//
//  Helper model for locations (Campus, Building, Room)
//  Developer: Noof Abdullah [202204310]
//

import Foundation
import FirebaseFirestore

// MARK: - Location Models
struct Campus: Codable {
    var campusId: String
    var name: String
    var buildings: [Building]
    
    enum CodingKeys: String, CodingKey {
        case campusId = "campus_id"
        case name
        case buildings
    }
}

struct Building: Codable {
    var buildingId: String
    var buildingName: String
    var rooms: [String]
    
    enum CodingKeys: String, CodingKey {
        case buildingId = "building_id"
        case buildingName = "building_name"
        case rooms
    }
}

// MARK: - Location Operations
class LocationManager {
    
    private static let db = Firestore.firestore()
    
    // MARK: - READ OPERATIONS
    
    static func fetchCampuses(completion: @escaping (Result<[Campus], Error>) -> Void) {
        db.collection("locations").document("campuses").getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = snapshot?.data(),
                  let campusesData = data["campuses"] as? [[String: Any]] else {
                completion(.success([]))
                return
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: campusesData)
                let campuses = try JSONDecoder().decode([Campus].self, from: jsonData)
                completion(.success(campuses))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    static func fetchCampusNames(completion: @escaping (Result<[String], Error>) -> Void) {
        fetchCampuses { result in
            switch result {
            case .success(let campuses):
                let names = campuses.map { $0.name }
                completion(.success(names))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    static func fetchBuildings(forCampus campusName: String, completion: @escaping (Result<[Building], Error>) -> Void) {
        fetchCampuses { result in
            switch result {
            case .success(let campuses):
                if let campus = campuses.first(where: { $0.name == campusName }) {
                    completion(.success(campus.buildings))
                } else {
                    completion(.success([]))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    static func fetchBuildingNames(forCampus campusName: String, completion: @escaping (Result<[String], Error>) -> Void) {
        fetchBuildings(forCampus: campusName) { result in
            switch result {
            case .success(let buildings):
                let names = buildings.map { $0.buildingName }
                completion(.success(names))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
