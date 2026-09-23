//
//  SocialView.swift
//  LiveChatFirebase
//
//  Created by Alexandre on 2026-05-16.
//

import SwiftUI

struct SocialView: View {
    var body: some View {
        TabView {
            ChatsView()
                .tabItem {
                    Label("Chats", systemImage: "message")
                }

            FriendsView()
                .tabItem {
                    Label("Amis", systemImage: "person.2")
                }
        }
        .navigationTitle("Messagerie")
        .navigationBarTitleDisplayMode(.inline)
    }
}
