//
//  CurrentUser.swift
//  RepairPro
//
//  Mock user for testing without Firebase Auth
//  Developer: Noof Abdullah [202204310]
//

import Foundation

class CurrentUser {
    
    // Singleton instance
    static let shared = CurrentUser()
    
    // Hardcoded user info (replace with real auth later)
    private(set) var userId: String = "user_1"
    private(set) var userName: String = "John Doe"
    private(set) var userEmail: String = "john.doe@example.com"
    
    private init() {}
    
    // MARK: - Easy Access Methods
    
    /// Returns current user ID
    static func getUserId() -> String {
        return shared.userId
    }
    
    /// Returns current user name
    static func getUserName() -> String {
        return shared.userName
    }
    
    /// Returns current user email
    static func getUserEmail() -> String {
        return shared.userEmail
    }
    
    /// Check if user is logged in (always true for now)
    static func isLoggedIn() -> Bool {
        return true
    }
    
    // MARK: - Update User (for testing different users)
    
    /// Change the mock user (useful for testing)
    static func setMockUser(id: String, name: String, email: String) {
        shared.userId = id
        shared.userName = name
        shared.userEmail = email
    }
}
