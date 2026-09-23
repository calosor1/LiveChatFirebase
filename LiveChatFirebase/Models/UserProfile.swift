//
//  UserProfile.swift
//  Tp4Base
//
//  Created by Alexandre Caisse on 2026-04-17.
//

import Foundation
import FirebaseFirestore

struct UserProfile: Codable, Identifiable {
    @DocumentID var id: String?
    
    var username: String
    var usernameLowercase: String
    var firstName: String
    var lastName: String
    var email: String
    var createdAt: Date
    var birthDate: Date
}


