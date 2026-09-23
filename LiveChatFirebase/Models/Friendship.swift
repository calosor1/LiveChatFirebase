//
//  Friendship.swift
//  Tp4Base
//
//  Created by Alexandre Caisse on 2026-04-24.
//


import Foundation
import FirebaseFirestore

struct Friendship: Codable, Identifiable {
    @DocumentID var id: String?
    //contrairement au AppState que lui le uid était créé lord du 
    //Auth.auth().createUser(withEmail: email, password: password)
    //et qu'on prenait ensuite : id: authResult.user.uid et qu'on
    //stockait dans firestore en faisant .document(authResult.user.uid)

    //ici pour Firendship et sûrement ChatMessage aussi, le @DocumentID va pas être injecté manuellement
    //mais juste créé random quand on fait db.collection("friendships").addDocument(from: friendship)
    //et génère random genre @DocumentID genre randomID123
    
    var ownerUserId: String
    var friendUserId: String
    var ownerUsername: String
    var friendUsername: String
    var status: FriendshipStatus
    var createdAt: Date

    //on a besoin du id du ownerUser et celui du friendUser car doit savoir pas juste qui est l'ami
    //mais aussi qui own cet amitiée.
    /*genre :
        db.collection("friendships")
            .whereField("ownerUserId", isEqualTo: "AlexUID")

        ainsi on obtient:
        friendUserId = BobUID
        friendUserId = CharlieUID

        on aurait pu juste stocker un tableau de friend id's genre friends: [uid]
        mais plus dur à query avec la bd qu'un filtre de recherche comme on a en haut
        donc moins flexible. Le modèle qu'on a présentement est plus flexible.
    */
}

enum FriendshipStatus: String, Codable {
    case pending
    case accepted
}
