//
//  ChatViewModel.swift
//  Tp4Base
//
//  Created by Alexandre Caisse on 2026-04-24.
//

import Foundation
import FirebaseFirestore
import Observation

@Observable //So SwiftUI can react when this ViewModel’s variables change.
@MainActor //Makes the ViewModel run on the main UI thread, because these variables affect what the screen displays.
class ChatViewModel {
    var messages: [ChatMessage] = [] // Stores the messages currently displayed in the chat.
    var text: String = "" // Stores what the user is typing in the message input field.
    var errorMessage: String = "" // Stores an error message if Firebase/listening/sending fails.
    var isLoading: Bool = false
    
    @ObservationIgnored
    private let db = Firestore.firestore() // Gets the shared Firestore database instance.
    
    @ObservationIgnored
    private var listener: ListenerRegistration?
    // Stores the active real-time listener for chat messages.
    // This is like authHandle from earlier: it lets us remove/stop the listener later.
    // It is not the listener itself
    // It is the handle (reference) to a listener

    //What is the actual listener?
    //It is this: .addSnapshotListener { snapshot, error in

    //What does it listen to?
    /*
        db.collection("conversations")
        .document(conversationId)
        .collection("messages")

        It listens ONLY to:
        The messages collection of ONE specific conversation
    */

    // Why @ObservationIgnored
    // Because SwiftUI does not need to observe these and since our class has @Observable, any variable inside
    // it would be observed to affect the UI, but these 2 variables are not needed for UI so we don't observe.
    // This avoids unnecessary observation work and possible
    // issues with Firebase objects that are not meant to be observed.
    
    
    func listen(conversationId: String) {
        listener?.remove() // Stop old listener
        //Before starting a new chat listener, stop the old one.
        //Otherwise if you open another conversation, you might still listen to the previous chat too.
        
        listener = db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "createdAt")
            //Build Firestore path to one conversation’s messages
            /*
                This whole chain is called a query:
                db.collection("conversations")
                .document(conversationId)
                .collection("messages")
                .order(by: "createdAt")

                The listener attaches to the entire query, not just one piece.

                It listens to:
                conversations / {conversationId} / messages

                BUT also respects:
                order(by: "createdAt")

                “Listen to all documents in this messages collection for this conversation, ordered by createdAt.”

                You are querying (on fait effectivement la requête,
                spa juste écoute cette requête sans rien exécuter).
                A listener is just a query that stays active.

                le .addSnapshotListener(...) ajouté au bout fait juste dire
                Run this query AND keep me updated when results change

                .order(by: "createdAt")
                does NOT mean “listen to order changes”
                “Give me the results of this query already sorted”

                so the .addSnapshotListener means:
                Run the query now, give me the result,
                and keep running it again every time data changes.

                So the query IS used to fetch data Right here:
                let newMessages = documents.compactMap { ... }
                This is the result of the query
                You are fetching data.
            */
            .addSnapshotListener { snapshot, error in //Attach real-time listener to that path

                //snapshot is the result of that query we built before it with the whole:
                /*
                    db.collection("conversations")
                    .document(conversationId)
                    .collection("messages")
                    .order(by: "createdAt")
                */
                
                //so we build a query, then attach a SnapshotListener to it
                //The result of the query is stored inside the variable snapshot when we do snapshot in
                //at the beginning of the opening braquets:

                //Firebase calls this block of code whenever messages change.

                //It sends either:
                //snapshot = latest messages result
                //error = nil

                //or it sends:
                //snapshot = nil / maybe partial
                //error = something went wrong
                
                // Every time Firestore sends data:
                //handle error
                //handle missing snapshot
                //convert documents to ChatMessage<
                //update UI messages

                //Si on résume:
                //In Firestore, go to conversations, then the document for this conversation,
                //then its messages subcollection, order messages by date, store that in snapshot variable
                //and update messages in UI, but then keep the query open and listen to changes there.
                //when messages changes because a new message is sent, then the block of code inside the
                //braquets of the SnapshotListener will run again (the query runs again) and we update
                //the messages to show in UI
                //So .addSnapshotListener comes after the path because
                //Firebase first needs to know what location/query to listen to.
                
                //Its like: Choose radio station first → then start listening

                if let error = error {
                    Task {
                        @MainActor in self.errorMessage = error.localizedDescription
                    }
                    return
                }
                //If Firebase reports an error, show it in the UI and stop.
                //The Task { @MainActor in ... } is because Firebase listener
                //callbacks may run outside the main UI thread, but errorMessage affects SwiftUI.
                
                guard let documents = snapshot?.documents else {
                    Task {
                        @MainActor in self.messages = []
                    }
                    return
                }
                //if there is a snapshot store its documents in documents
                //else If there is no usable snapshot, clear messages and stop.
                //After this line, Swift knows if documents exists.
                
                let newMessages = documents.compactMap {
                    try? $0.data(as: ChatMessage.self)
                }
                //convert Firestore documents into models
                
                Task {
                    @MainActor in self.messages = newMessages
                }
                //Put the converted messages into the ViewModel so the chat screen updates.
            }
    }
    
    func sendMessage(conversationId: String, senderId: String) async {
        guard !text.isEmpty else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let userDocument = try await db.collection("users")
                .document(senderId)
                .getDocument()

            guard let user = try? userDocument.data(as: UserProfile.self) else {
                errorMessage = "Impossible de récupérer le nom d'utilisateur"
                return
            }

            let message = ChatMessage(
                senderId: senderId,
                senderUsername: user.username,
                text: text,
                createdAt: Date()
            )

            try db.collection("conversations")
                .document(conversationId)
                .collection("messages")
                .addDocument(from: message)

            text = ""

        } catch {
            errorMessage = "Erreur Firebase: \(error)"
        }
    }
    
    func stopListening() {
        listener?.remove() //Stop sending updates for this query
        listener = nil //We no longer have an active listener
    }
    //Stops the real-time listene
    //remove() → stops Firebase updates
    //nil → avoids holding a useless reference in memory
    
    deinit {
        listener?.remove()
    }
    //Automatically called when the ChatViewModel is destroyed (removed from memory)
    //Ensures even if you forgot to call stopListening(), the listener is still cleaned up
    
}
