//
//  FriendsView.swift
//
//
//  Created by Alexandre Caisse on 2026-04-17.
//

import SwiftUI

struct FriendsView: View {
    @Environment(AppStateViewModel.self) private var appState

    @State private var friendsViewModel = FriendsViewModel()
    @State private var searchText = ""
    @State private var showReceivedRequests = false
    @State private var showSentRequests = false
    
    @State private var showFriendAlert = false
    @State private var friendAlertMessage = ""

    var body: some View {
        VStack(spacing: 12) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Amis")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    searchSection
                    messageSection
                    searchResultsSection
                    friendsSection
                }
                .padding()
            }

            requestButtons
                .padding(.horizontal)
                .padding(.bottom)
        }
        .navigationTitle("Amis")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await reloadData()
        }
        .sheet(isPresented: $showReceivedRequests) {
            receivedRequestsSheet
        }
        .sheet(isPresented: $showSentRequests) {
            sentRequestsSheet
        }
        .alert("Information", isPresented: $showFriendAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(friendAlertMessage)
        }
    }

    private var searchSection: some View {
        VStack(spacing: 12) {
            TextField("Rechercher par nom d'utilisateur", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            Button {
                Task {
                    guard let currentUserId = appState.userProfile?.id else { return }
                    await friendsViewModel.searchUser(
                        currentUserID: currentUserId,
                        searchText: searchText
                    )
                }
            } label: {
                Text("Rechercher")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(friendsViewModel.isLoading)
        }
    }

    private var messageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !friendsViewModel.errorMessage.isEmpty {
                Text(friendsViewModel.errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            if !friendsViewModel.successMessage.isEmpty {
                Text(friendsViewModel.successMessage)
                    .foregroundColor(.green)
                    .font(.caption)
            }
        }
    }

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !friendsViewModel.searchResult.isEmpty {
                Text("Résultats")
                    .font(.headline)

                ForEach(friendsViewModel.searchResult, id: \.id) { user in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(user.username)
                                .font(.headline)

                            Text("\(user.firstName) \(user.lastName)")
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button("Ajouter") {
                            Task {
                                guard let userId = appState.userProfile?.id,
                                      let friendUserId = user.id else { return }

                                await friendsViewModel.addFriend(
                                    currentUserId: userId,
                                    friendUserId: friendUserId
                                )

                                if !friendsViewModel.successMessage.isEmpty {
                                    friendAlertMessage = friendsViewModel.successMessage
                                    showFriendAlert = true

                                    searchText = ""
                                    friendsViewModel.searchResult = []
                                } else if !friendsViewModel.errorMessage.isEmpty {
                                    friendAlertMessage = friendsViewModel.errorMessage
                                    showFriendAlert = true
                                }

                                await reloadData()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.12))
                    .cornerRadius(10)
                }
            }
        }
    }

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mes amis")
                .font(.headline)

            if friendsViewModel.friends.isEmpty {
                Text("Aucun ami pour le moment.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(friendsViewModel.friends, id: \.id) { friend in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(friend.username)
                                .font(.headline)

                            Text("\(friend.firstName) \(friend.lastName)")
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.12))
                    .cornerRadius(10)
                }
            }
        }
    }

    private var requestButtons: some View {
        HStack(spacing: 12) {
            Button("Demandes reçues") {
                showReceivedRequests = true
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.borderedProminent)

            Button("Demandes envoyées") {
                showSentRequests = true
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.bordered)
        }
    }

    private var receivedRequestsSheet: some View {
        NavigationStack {
            List {
                if friendsViewModel.receivedRequests.isEmpty {
                    Text("Aucune demande reçue.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(friendsViewModel.receivedRequests, id: \.id) { request in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Demande d'ami")
                                .font(.headline)

                            Text("Utilisateur: \(request.ownerUsername)")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack {
                                Button("Accepter") {
                                    Task {
                                        await friendsViewModel.acceptRequest(request)

                                        if !friendsViewModel.successMessage.isEmpty {
                                            friendAlertMessage = friendsViewModel.successMessage
                                            showFriendAlert = true
                                        } else if !friendsViewModel.errorMessage.isEmpty {
                                            friendAlertMessage = friendsViewModel.errorMessage
                                            showFriendAlert = true
                                        }

                                        await reloadData()
                                    }
                                }
                                .buttonStyle(.borderedProminent)

                                Button("Refuser") {
                                    Task {
                                        await friendsViewModel.refuseRequest(request)

                                        if !friendsViewModel.successMessage.isEmpty {
                                            friendAlertMessage = friendsViewModel.successMessage
                                            showFriendAlert = true
                                        } else if !friendsViewModel.errorMessage.isEmpty {
                                            friendAlertMessage = friendsViewModel.errorMessage
                                            showFriendAlert = true
                                        }

                                        await reloadData()
                                    }
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("Demandes reçues")
            .toolbar {
                Button("Fermer") {
                    showReceivedRequests = false
                }
            }
        }
    }

    private var sentRequestsSheet: some View {
        NavigationStack {
            List {
                if friendsViewModel.sentRequests.isEmpty {
                    Text("Aucune demande envoyée.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(friendsViewModel.sentRequests, id: \.id) { request in
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Demande en attente")
                                .font(.headline)

                            Text("Utilisateur: \(request.friendUsername)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("Demandes envoyées")
            .toolbar {
                Button("Fermer") {
                    showSentRequests = false
                }
            }
        }
    }

    private func reloadData() async {
        guard let userId = appState.userProfile?.id else { return }

        await friendsViewModel.loadFriends(currentUserId: userId)
        await friendsViewModel.loadReceivedRequests(currentUserId: userId)
        await friendsViewModel.loadSentRequests(currentUserId: userId)
    }
}
