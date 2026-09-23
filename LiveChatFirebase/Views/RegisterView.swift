//
//  RegisterView.swift
//
//
//  Created by Alexandre Caisse on 2026-04-17.
//

import SwiftUI

struct RegisterView: View {
    @Environment(AppStateViewModel.self) private var appState

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var birthDate = Date()

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("Créer un compte")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                VStack(spacing: 12) {
                    TextField("Nom d'utilisateur", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("Prénom", text: $firstName)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()

                    TextField("Nom", text: $lastName)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()

                    TextField("Courriel", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()

                    DatePicker("Date de naissance", selection: $birthDate, displayedComponents: .date)

                    SecureField("Mot de passe", text: $password)
                        .textFieldStyle(.roundedBorder)

                    SecureField("Confirmation du mot de passe", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)
                }

                if !appState.errorMessage.isEmpty {
                    Text(appState.errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task {
                        await appState.signup(
                            email: email,
                            password: password,
                            confirmPassword: confirmPassword,
                            userName: username,
                            firstName: firstName,
                            lastName: lastName,
                            birthDate: birthDate
                        )
                    }
                } label: {
                    if appState.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Créer un compte")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Inscription")
        .navigationBarTitleDisplayMode(.inline)
    }
}
