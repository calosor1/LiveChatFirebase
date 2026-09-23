//
//  ChatsView.swift
//  LiveChatFirebase
//
//  Created by Alexandre on 2026-05-16.
//

import SwiftUI

struct ChatsView: View {
    @Environment(AppStateViewModel.self) private var appState

    @State private var friendsViewModel = FriendsViewModel()
    @State private var conversationsViewModel = ConversationsViewModel()

    @State private var showCreateGroup = false
    @State private var groupTitle = ""
    @State private var selectedFriendIds: Set<String> = []
    //similaire à un array de string, mais empêche les duplicates.
    //https://developer.apple.com/documentation/swift/set

    @State private var selectedConversationId = ""
    @State private var openChat = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Chats")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal)

                messageSection
                    .padding(.horizontal)

                createGroupButton
                    .padding(.horizontal)

                conversationsSection

                privateChatsSection
            }
            .padding(.top)
            .navigationTitle("Chats")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await reloadData()
            }
            .sheet(isPresented: $showCreateGroup) {
                createGroupSheet
            }
            .navigationDestination(isPresented: $openChat) {
                if let currentUserId = appState.userProfile?.id {
                    ChatView(
                        conversationId: selectedConversationId,
                        currentUserId: currentUserId
                    )
                }
            }
        }
    }

    private var messageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !conversationsViewModel.errorMessage.isEmpty {
                Text(conversationsViewModel.errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            if !conversationsViewModel.successMessage.isEmpty {
                Text(conversationsViewModel.successMessage)
                    .foregroundColor(.green)
                    .font(.caption)
            }
        }
    }

    private var createGroupButton: some View {
        Button {
            showCreateGroup = true
        } label: {
            Text("Créer un groupe")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }

    private var conversationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Conversations")
                .font(.headline)
                .padding(.horizontal)

            if conversationsViewModel.conversations.isEmpty {
                Text("Aucune conversation existante.")
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .frame(height: 180, alignment: .top)
            } else {
                List(conversationsViewModel.conversations, id: \.id) { conversation in
                    if let conversationId = conversation.id,
                       let currentUserId = appState.userProfile?.id {
                        NavigationLink {
                            ChatView(
                                conversationId: conversationId,
                                currentUserId: currentUserId
                            )
                        } label: {
                            HStack {
                                Image(systemName: conversation.isGroup ? "person.3.fill" : "person.fill")
                                    .foregroundColor(.blue)

                                VStack(alignment: .leading) {
                                    Text(conversation.title)
                                        .font(.headline)

                                    Text(conversation.isGroup ? "Groupe" : "Conversation privée")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .frame(height: 230)
            }
        }
    }

    private var privateChatsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Démarrer une conversation privée")
                .font(.headline)
                .padding(.horizontal)

            if friendsViewModel.friends.isEmpty {
                Text("Aucun ami disponible.")
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .frame(height: 180, alignment: .top)
            } else {
                List(friendsViewModel.friends, id: \.id) { friend in
                    Button {
                        Task {
                            guard let currentUserId = appState.userProfile?.id else { return }

                            if let conversationId = await conversationsViewModel.createPrivateConversation(
                                currentUserId: currentUserId,
                                friend: friend
                            ) {
                                selectedConversationId = conversationId
                                openChat = true
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "plus.message.fill")
                                .foregroundColor(.blue)

                            VStack(alignment: .leading) {
                                Text(friend.username)
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text("Créer / ouvrir une conversation")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .frame(height: 230)
            }
        }
    }

    private var createGroupSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                TextField("Nom du groupe", text: $groupTitle)
                    .textFieldStyle(.roundedBorder)

                Text("Choisir des amis")
                    .font(.headline)

                if friendsViewModel.friends.isEmpty {
                    Text("Aucun ami disponible.")
                        .foregroundColor(.secondary)
                } else {
                    List(friendsViewModel.friends, id: \.id) { friend in
                        if let friendId = friend.id {
                            Button {
                                if selectedFriendIds.contains(friendId) {
                                    selectedFriendIds.remove(friendId)
                                } else {
                                    selectedFriendIds.insert(friendId)
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(friend.username)
                                            .foregroundColor(.primary)

                                        Text("\(friend.firstName) \(friend.lastName)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    if selectedFriendIds.contains(friendId) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }

                Button {
                    Task {
                        guard let currentUserId = appState.userProfile?.id else { return }

                        if let groupId = await conversationsViewModel.createGroup(
                            title: groupTitle,
                            currentUserId: currentUserId,
                            selectedFriendIds: Array(selectedFriendIds)
                        ) {
                            groupTitle = ""
                            selectedFriendIds = []
                            showCreateGroup = false
                            selectedConversationId = groupId
                            openChat = true
                        }
                    }
                } label: {
                    Text("Créer le groupe")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
            .navigationTitle("Nouveau groupe")
            .toolbar {
                Button("Fermer") {
                    showCreateGroup = false
                }
            }
        }
    }

    private func reloadData() async {
        guard let userId = appState.userProfile?.id else { return }

        await friendsViewModel.loadFriends(currentUserId: userId)
        await conversationsViewModel.loadConversations(currentUserId: userId)
    }
}
