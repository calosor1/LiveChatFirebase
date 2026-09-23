//
//  HomeView.swift
//  Tp4Base
//
//  Created by Alexandre Caisse on 2026-04-17.
//

import SwiftUI

struct HomeView: View {
    @Environment(AppStateViewModel.self) private var appState

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Text("Bienvenue")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                if let profile = appState.userProfile {
                    VStack(spacing: 8) {
                        Text("Bonjour, \(profile.username)")
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text("\(profile.firstName) \(profile.lastName)")
                            .foregroundColor(.secondary)
                    }
                } else {
                    ProgressView("Chargement du profil...")
                }

                VStack(spacing: 12) {
                    NavigationLink {
                        SocialView()
                    } label: {
                        Text("Messagerie")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Button {
                        appState.signout()
                    } label: {
                        Text("Se déconnecter")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.9))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Accueil")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
