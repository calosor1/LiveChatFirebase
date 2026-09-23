//
//  ChatView.swift
//  Tp4Base
//
//  Created by Alexandre Caisse on 2026-04-24.
//

import SwiftUI
import FirebaseFirestore

struct ChatView: View {
    let conversationId: String
    let currentUserId: String

    @State private var viewModel = ChatViewModel()

    var body: some View {
        VStack(spacing: 12) {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(viewModel.messages) { message in
                        messageRow(message)
                    }
                }
                .padding()
            }

            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            inputSection
        }
        .navigationTitle("Discussion")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.listen(conversationId: conversationId)
        }
        .onDisappear {
            viewModel.stopListening()
        }
    }

    private func messageRow(_ message: ChatMessage) -> some View {
        let isCurrentUser = message.senderId == currentUserId

        return HStack {
            if isCurrentUser {
                Spacer()
            }

            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.senderId == currentUserId ? "Vous" : message.senderUsername)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Text(message.text)
                    .padding()
                    .background(isCurrentUser ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(isCurrentUser ? .white : .primary)
                    .cornerRadius(12)

                Text(message.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if !isCurrentUser {
                Spacer()
            }
        }
    }

    private var inputSection: some View {
        HStack {
            TextField("Message...", text: $viewModel.text)
                .textFieldStyle(.roundedBorder)

            Button {
                Task {
                    await viewModel.sendMessage(
                        conversationId: conversationId,
                        senderId: currentUserId
                    )
                }
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Text("Envoyer")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
    }
}

