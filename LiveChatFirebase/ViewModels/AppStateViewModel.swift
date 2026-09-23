//
//  AppStateViewModel.swift
//
//
//  Created by Alexandre Caisse on 2026-04-17.
//

import Foundation
import Observation
import FirebaseAuth
import FirebaseFirestore

@Observable
@MainActor
class AppStateViewModel {
    var isAuthenticated = false
    var isLoading = false
    var errorMessage = ""
    var successMessage = ""
    
    var userProfile: UserProfile?
    
    private let db = Firestore.firestore()
    private var authHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        listenToAuthState()
    }
    
    private func listenToAuthState() {
        authHandle = Auth.auth().addStateDidChangeListener{[weak self] _, user
            in Task { @MainActor in
                guard let self else {return}
                
                self.isAuthenticated = (user != nil)
                
                if user != nil {
                    await self.loadUserProfile()
                } else {
                    self.userProfile = nil
                }
            }
        }
    }
    
    private func loadUserProfile() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            userProfile = nil
            return
        }
        
        do {
            let snapshot = try await db.collection("users").document(uid).getDocument()
            userProfile = try snapshot.data(as: UserProfile.self)
            
        } catch {
            userProfile = nil
        }
        
    }
    
    func signin(email: String, password: String) async {
        errorMessage = ""
        successMessage = ""
        
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Veuillez remplir tous les champs"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            errorMessage = firebaseErrorHandler(error)
        }
    }
    
    
    func signup(email: String, password: String, confirmPassword: String, userName: String, firstName: String, lastName: String, birthDate: Date ) async {
        errorMessage = ""
        successMessage = ""
        
        guard !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty,!userName.isEmpty, !firstName.isEmpty, !lastName.isEmpty else {
            errorMessage = "Veuillez remplir tous les champs"
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Les mots de passe ne correspondent pas"
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Le mot de passe doit contenir au moins 6 caractères"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
           let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            
            let profile = UserProfile(
                id: authResult.user.uid,
                username: userName,
                usernameLowercase: userName.lowercased(),
                firstName: firstName,
                lastName: lastName,
                email: email,
                createdAt: Date(),
                birthDate: birthDate
            )
            try db.collection("users")
                .document(authResult.user.uid)
                .setData(from: profile)
        } catch {
            errorMessage = firebaseErrorHandler(error)
        }
    }
    
    func signout()  {
        errorMessage = ""
        successMessage = ""
        
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = firebaseErrorHandler(error)
        }
    }
    
    func resetPassword(email: String) async {
        errorMessage = ""
        successMessage = ""

        guard !email.isEmpty else {
            errorMessage = "Veuillez entrer votre courriel"
            return
        }

        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            successMessage = "Un courriel de réinitialisation a été envoyé."
        } catch {
            errorMessage = firebaseErrorHandler(error)
        }
    }
    
    private func firebaseErrorHandler(_ error: Error) -> String {
        guard let errorCode = AuthErrorCode(rawValue: error._code) else {
            return "une erreur inconnue est survenue"
        }
        
        switch errorCode {
        case .invalidEmail:
            return "L'adresse email fournie est invalide"
        case .invalidCredential:
            return "Le mot de passe ou l'adresse email sont incorrects"
        case .weakPassword:
            return "Le mot de passe doit contenir au moins 6 caractères"
        case .networkError:
            return "Problème de connexion internet"
        case .emailAlreadyInUse:
            return "Un compte avec cette adresse email existe déjà"
        default:
            return "Erreur Firebase: \(error.localizedDescription) (code: \(errorCode.rawValue))"
        }
    }
}

