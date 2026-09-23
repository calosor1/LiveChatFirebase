//
//  LiveChatFirebaseApp.swift
//  LiveChatFirebase
//
//  Created by Alexandre on 2026-05-15.
//

import SwiftUI
import FirebaseCore

@main
struct LiveChatFirebaseApp: App {
    @State private var appState: AppStateViewModel
    
    init() {
        FirebaseApp.configure()
        _appState = State(initialValue: AppStateViewModel())
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
    }
}
