//
//  ChatMessage.swift
//  Tp4Base
//
//  Created by Alexandre Caisse on 2026-04-24.
//

import Foundation
import FirebaseFirestore

struct ChatMessage: Codable, Identifiable {
    @DocumentID var id: String?
    //généré automatiquement quand insère dedans Firestore
    
    var senderId: String //savoir qui pour display messages left/right in UI (know who wrote what)
    var senderUsername: String
    var text: String
    var createdAt: Date //montrer le temps, in real-time updates, ordering messages
}
