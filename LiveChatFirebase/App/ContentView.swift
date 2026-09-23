//
//  ContentView.swift
//  LiveChatFirebase
//
//  Created by Alexandre on 2026-05-15.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppStateViewModel.self) private var appState
    var body: some View {
        if appState.isAuthenticated {
            HomeView()
        } else {
            NavigationStack{
                LoginView()
            }
            
        }
    }
}

#Preview {
    ContentView()
        .environment(AppStateViewModel())
}
