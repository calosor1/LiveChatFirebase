//
//  Conversation.swift
//  LiveChatFirebase
//
//  Created by Alexandre on 2026-05-16.
//

import Foundation
import FirebaseFirestore

struct Conversation: Codable, Identifiable {
    @DocumentID var id: String?

    var title: String
    var participantIds: [String]
    var isGroup: Bool
    var createdAt: Date
}
