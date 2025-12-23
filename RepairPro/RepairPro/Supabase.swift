//
//  Supabase.swift
//  auth-example
//
//  Created by Ahmed on 17/11/2025.
//

import Foundation
import Supabase

class SupabaseClientManager {
    static let shared = SupabaseClientManager()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://wlefukllkrvgpjelkxav.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndsZWZ1a2xsa3J2Z3BqZWxreGF2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY0ODY3OTYsImV4cCI6MjA4MjA2Mjc5Nn0.vvCzIhXWgwR4fiGZkJgexctxnVNT9zy7Xmo_e1CnO5k",
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }
}
