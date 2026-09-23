//
//  LoginView.swift
//
//
//  Created by Alexandre Caisse on 2026-04-17.
//

import SwiftUI

struct LoginView: View {
    @Environment(AppStateViewModel.self) private var appState

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Connexion")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                TextField("Courriel", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()

                SecureField("Mot de passe", text: $password)
                    .textFieldStyle(.roundedBorder)
                
                Button("Mot de passe oublié?") {
                    Task {
                        await appState.resetPassword(email: email)
                    }
                }
                .font(.footnote)
            }

            if !appState.errorMessage.isEmpty {
                Text(appState.errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            
            if !appState.successMessage.isEmpty {
                Text(appState.successMessage)
                    .foregroundColor(.green)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task {
                    await appState.signin(email: email, password: password)
                }
            } label: {
                if appState.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Connexion")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }

            NavigationLink("Créer un compte") {
                RegisterView()
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Connexion")
        .navigationBarTitleDisplayMode(.inline)
    }
}
