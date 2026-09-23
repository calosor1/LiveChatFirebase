//
//  FriendsViewModel.swift
//  Tp4Base
//
//  Created by Alexandre Caisse on 2026-04-24.
//

import Foundation
import Observation
import FirebaseFirestore

@Observable //So SwiftUI can react when this ViewModel’s variables change.
@MainActor //Makes the ViewModel run on the main UI thread, because these variables affect what the screen displays.
class FriendsViewModel {
    var searchResult: [UserProfile] = [] //liste des users matchant notre recherche
    var friends: [UserProfile] = [] //liste d'amis
    var receivedRequests: [Friendship] = []
    var sentRequests: [Friendship] = []
    var errorMessage = ""
    var successMessage = ""
    var isLoading = false
    
    private let db = Firestore.firestore() //get the shared firestore instance
    
    func searchUser(currentUserID: String, searchText: String) async {
        errorMessage = ""
        searchResult = []
        
        guard !searchText.isEmpty else {
            errorMessage = "Veuillez entrer un critère"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let snapshot = try await db.collection("users")
                .whereField("username", isGreaterThanOrEqualTo: searchText)
                //Find usernames that start around the search text.
                //Start reading from the page where words reach al or later
                //so it can return alice but cann also return amanda because m is greater than l
                //it can even return zebra cause Z is greater than A so comparison stops immediately
                //basically we compare 2 full strings, the comparison gets unequeal the moment 1 letter is different
                //so for example amanda vs al (username amanda comes first because it
                //is what gets compared to the boundary)
                //a == a so its good then compare m to l, m is greater than l so works
                //zebra vs al, the first letter is immediately different, z is greater than a so works
                .whereField("username", isLessThan: searchText+"\u{f8ff}")
                //Upper bound trick: includes usernames that begin with searchText.
                //here we compare with al + highest possible suffix character
                //so imagine "alex" vs "al"
                // a == a then l == l then oh no the character is different, we check is
                // x < than  the answer is yes cause  is highest possible suffix
                // so the string alex is less than al

                /*
                    les 2 filtres ensemble font que ont a:
                    "al" ≤ username < "al\u{f8ff}"
                    donc garde:
                        alex
                        alice
                        albert
                    mais pas:
                        amanda
                        bob
                        zebra
                */
                .order(by: "username")
                .limit(to: 10)
                .getDocuments() //actually runs the query

                //why snapshot?:
                //Because Firestore returns a query result package, not directly [UserProfile].
                /*
                the snapshot contains:
                    documents
                    metadata
                    query result info

                Then you extract the documents by doing snapshot.documents
                */
            
            let result = snapshot.documents.compactMap { try? $0.data(as: UserProfile.self) }
                .filter { $0.id != currentUserID }
                //le filtre: It removes yourself from the search results.
            
            //map would do: [UserProfile?, UserProfile?, nil, UserProfile?]
            //compactMap does: [UserProfile, UserProfile, UserProfile]
            //try because the conversion can fail
            //0$ represent each document
            //.data(as:) Convert Firestore document → Swift struct UserProfile
            
            guard !result.isEmpty else {
                errorMessage = "Aucun utilisateur trouvé"
                return
            }
            
            searchResult = result
            
        } catch {
            errorMessage = "Une erreur est survenue: \(error)"
        }
    }
    
    func addFriend(currentUserId: String, friendUserId: String) async {
        errorMessage = ""
        successMessage = ""
        isLoading = true
        defer { isLoading = false }
        
        guard currentUserId != friendUserId else {
            errorMessage = "Vous ne pouvez pas ajouter vous-même comme ami"
            return
        }
        
        do {
            let existingFriend = try await db.collection("friendships")
                .whereField("ownerUserId", isEqualTo: currentUserId)
                .whereField("friendUserId", isEqualTo: friendUserId)
                .getDocuments() //execute la query pouur pogner le bon snapshot
                //rappel un snapshot contient plusieurs trucs comme metadata et autres, mais l'un
                //des attributs est bien documents (un array genre [DocumentSnapshot, DocumentSnapshot, ...])

            //Cherche si un friendship existe déjà pour cet owner avec ce friend
            //si oui et arrive à faire getDocuments (return un snapshot qui contient
            // metadata, documents et autre) et store dedans exitingFriend variable
            //then sera capable de faire existingFriend.documents sans que ce soit vide

            //documents est toujours un array, mais juste 1 élément à cause de nos filtres alors peut faire .first
            if let document = existingFriend.documents.first,
               let friendship = try? document.data(as: Friendship.self) {

                switch friendship.status {
                case .pending:
                    errorMessage = "Vous avez déjà envoyé une demande à cet utilisateur"
                    return

                case .accepted:
                    errorMessage = "Cet utilisateur est déjà dans vos amis"
                    return
                }
            }
            
            let reverseRequest = try await db.collection("friendships")
                .whereField("ownerUserId", isEqualTo: friendUserId)
                .whereField("friendUserId", isEqualTo: currentUserId)
                .getDocuments()

            if let document = reverseRequest.documents.first,
               let friendship = try? document.data(as: Friendship.self) {

                switch friendship.status {
                case .pending:
                    errorMessage = "Cet utilisateur vous a déjà envoyé une demande. Vous pouvez l'accepter dans vos demandes reçues."
                    return

                case .accepted:
                    errorMessage = "Cet utilisateur est déjà dans vos amis"
                    return
                }
            }
            
            let currentUserDocument = try await db.collection("users")
                .document(currentUserId)
                .getDocument()
            
            let friendUserDocument = try await db.collection("users")
                .document(friendUserId)
                .getDocument()
            
            guard let currentUser = try? currentUserDocument.data(as: UserProfile.self),
                  let friendUser = try? friendUserDocument.data(as: UserProfile.self) else {
                errorMessage = "Impossible de récupérer les informations des utilisateurs"
                return
            }
            
            let friendship = Friendship( //construit un friendship object
                ownerUserId: currentUserId,
                friendUserId: friendUserId,
                ownerUsername: currentUser.username,
                friendUsername: friendUser.username,
                status: .pending,
                createdAt: Date()
            )
            
            try db.collection("friendships").addDocument(from: friendship)
            //add dedans la database et un @DocumentID sera généré automatiquement
            successMessage = "Demande d’ami envoyée"
        } catch {
            errorMessage = "Une erreur s'est produite: \(error)"
        }
    }
    
    func loadFriends(currentUserId: String) async {
        errorMessage = ""
        successMessage = ""
        isLoading = true
        defer { isLoading = false }

        do {
            let ownerSnapshot = try await db.collection("friendships")
                .whereField("ownerUserId", isEqualTo: currentUserId)
                .whereField("status", isEqualTo: FriendshipStatus.accepted.rawValue)
                .getDocuments()

            let friendSnapshot = try await db.collection("friendships")
                .whereField("friendUserId", isEqualTo: currentUserId)
                .whereField("status", isEqualTo: FriendshipStatus.accepted.rawValue)
                .getDocuments()

            let ownerFriendships = try ownerSnapshot.documents.compactMap { document in
                try document.data(as: Friendship.self)
            }
            /*
                ici juste syntaxe différente plus explicite, mais même chose que :
                myFriendsSnapshot.documents.compactMap {
                    try $0.data(as: Friendship.self)
                }

                doit mettre document in quand on prend un custom name au lieu du shortcut $0
                puisque qu'on fait un for each, donc:
                For each element, call it document, and use it inside.
                comme si on faisait (parameter) → code
                genre quand tu fais { document in ... } sa veut dire “take document, then run this code”
            */

            let friendFriendships = try friendSnapshot.documents.compactMap { document in
                try document.data(as: Friendship.self)
            }

            var friendIds: [String] = []

            for friendship in ownerFriendships {
                friendIds.append(friendship.friendUserId)
            }
            //ajoute les friends des friendships qu'on est owner

            for friendship in friendFriendships {
                friendIds.append(friendship.ownerUserId)
            }
            //ajoute les friends des friendships que l'ami est owner

            guard !friendIds.isEmpty else {
                friends = []
                return
            }

            let usersSnapshot = try await db.collection("users")
                .whereField(FieldPath.documentID(), in: friendIds)
                .getDocuments()

            friends = try usersSnapshot.documents.compactMap { document in
                try document.data(as: UserProfile.self)
            }

        } catch {
            errorMessage = "Impossible de charger les amis: \(error)"
        }
    }
    
    func loadReceivedRequests(currentUserId: String) async {
        errorMessage = ""
        successMessage = ""

        do {
            let snapshot = try await db.collection("friendships")
                .whereField("friendUserId", isEqualTo: currentUserId) //reçues
                .whereField("status", isEqualTo: FriendshipStatus.pending.rawValue)
                .getDocuments()
            //.rawvalue car doit comparer avec donnée rangée dans Firestore et Firestore lui store nos
            //données d'énum en rawValue automatiquement dans la BD

            receivedRequests = try snapshot.documents.compactMap { document in
                try document.data(as: Friendship.self)
                //map chaque document en un friendship object
            }

        } catch {
            errorMessage = "Impossible de charger les demandes reçues: \(error)"
        }
    }
    
    func loadSentRequests(currentUserId: String) async {
        errorMessage = ""
        successMessage = ""

        do {
            let snapshot = try await db.collection("friendships")
                .whereField("ownerUserId", isEqualTo: currentUserId) //envoyées
                .whereField("status", isEqualTo: FriendshipStatus.pending.rawValue)
                .getDocuments()

            sentRequests = try snapshot.documents.compactMap { document in
                try document.data(as: Friendship.self)
            }

        } catch {
            errorMessage = "Impossible de charger les demandes envoyées: \(error)"
        }
    }
    
    func acceptRequest(_ request: Friendship) async {
        errorMessage = ""
        successMessage = ""

        guard let requestId = request.id else {
            errorMessage = "Impossible de trouver la demande"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await db.collection("friendships")
                .document(requestId)
                .updateData([
                    "status": FriendshipStatus.accepted.rawValue
                ])

            successMessage = "Demande acceptée"

        } catch {
            errorMessage = "Impossible d'accepter la demande: \(error)"
        }
    }
    
    func refuseRequest(_ request: Friendship) async {
        errorMessage = ""
        successMessage = ""

        guard let requestId = request.id else {
            errorMessage = "Impossible de trouver la demande"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await db.collection("friendships")
                .document(requestId)
                .delete()

            successMessage = "Demande refusée"

        } catch {
            errorMessage = "Impossible de refuser la demande: \(error)"
        }
    }
    
    func getConversationId(user1: String, user2: String) -> String {
        return [user1, user2].sorted().joined(separator: "_")
    }
    //This creates a unique and consistent ID for a conversation between 2 users.

    //is not used in FriendsViewModel directly.
    //It is prepared for the Chat system.

    /*
        It will be used in chat, but it is kept here in FriendsViewModel because:

            friends list determines who you can chat with
            conversation ID depends on both users
            So it’s logically related.
    */

    /*
        Example:
        [user1, user2] genre ["alexUID", "bobUID"]

        .sorted() veut dire alphabetical order alors
        ["bobUID", "alexUID"] → ["alexUID", "bobUID"]
        
        .joined(separator: "_") donc:
        "alexUID_bobUID"

        Si on faisait pas un sort, le id de conversation serait pas le même entre user 1 et 2
        car selon de quel bord on L'effectue mettons si Alex est user 1 (le owner) versus user 2 (le friend)
        le conversationId serait pas le même.

        getConversationId("alex", "bob") → "alex_bob"
        getConversationId("bob", "alex") → "bob_alex"
        donc 2 id différents

        sorted() permet d'avoir le meme id peut importe si c'est du bord de Alex qu'on check ou du bord de Bob
    */
}
