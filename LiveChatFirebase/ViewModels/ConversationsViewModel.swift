//
//  ConversationsViewModel.swift
//  LiveChatFirebase
//
//  Created by Alexandre on 2026-05-16.
//

import Foundation
import Observation
import FirebaseFirestore

@Observable
@MainActor
class ConversationsViewModel {
    var conversations: [Conversation] = []
    var errorMessage = ""
    var successMessage = ""
    var isLoading = false

    private let db = Firestore.firestore()

    func loadConversations(currentUserId: String) async {
        errorMessage = ""
        successMessage = ""

        do {
            let snapshot = try await db.collection("conversations")
                .whereField("participantIds", arrayContains: currentUserId)
                .getDocuments()

            conversations = try snapshot.documents.compactMap { document in
                try document.data(as: Conversation.self)
            }

        } catch {
            errorMessage = "Impossible de charger les conversations: \(error)"
        }
    }

    func createPrivateConversation(currentUserId: String, friend: UserProfile) async -> String? {
        //return string? car besoin du id de la convo pour l'ouvrir tout suite quand c'est une convo privée
        errorMessage = ""
        successMessage = ""

        guard let friendId = friend.id else {
            errorMessage = "Impossible de trouver cet ami"
            return nil
        }

        let conversationId = [currentUserId, friendId].sorted().joined(separator: "_")

        do {
            //check si convo existe déjà
            let document = try await db.collection("conversations")
                .document(conversationId)
                .getDocument()

            //si existe pas on en crée une
            if !document.exists {
                let conversation = Conversation(
                    title: friend.username,
                    participantIds: [currentUserId, friendId],
                    isGroup: false,
                    createdAt: Date()
                )

                //crée la conversation
                //pas de await vu écrire dans BD en Firebase sont pas des méthodes définies async on dirait
                //est async par contre quand on fetch et attend des données (plus haut quand regarde si convo existe)
                try db.collection("conversations")
                    .document(conversationId)
                    .setData(from: conversation)
            }
            
            await loadConversations(currentUserId: currentUserId)

            return conversationId

        } catch {
            errorMessage = "Impossible de créer la conversation: \(error)"
            return nil
        }
    }

    func createGroup(title: String, currentUserId: String, selectedFriendIds: [String]) async -> String? {
        errorMessage = ""
        successMessage = ""

        guard !title.isEmpty else {
            errorMessage = "Veuillez entrer un nom de groupe"
            return nil
        }

        guard !selectedFriendIds.isEmpty else {
            errorMessage = "Veuillez choisir au moins un ami"
            return nil
        }

        isLoading = true
        defer { isLoading = false }

        do {
            var participantIds = selectedFriendIds
            participantIds.append(currentUserId)

            let conversation = Conversation(
                title: title,
                participantIds: participantIds,
                isGroup: true,
                createdAt: Date()
            )

            let documentReference = try db.collection("conversations")
                .addDocument(from: conversation)

            successMessage = "Groupe créé"
            await loadConversations(currentUserId: currentUserId)

            return documentReference.documentID

        } catch {
            errorMessage = "Impossible de créer le groupe: \(error)"
            return nil
        }
    }
}
