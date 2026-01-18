//
//  ContentView.swift
//  LLMDemo
//
//  Created by Conner Yoon on 1/17/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var gameManager = GameManager()

    var body: some View {
        MainMenuView(gameManager: gameManager)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [APIKeyStore.self, ChatMessage.self, GameSession.self])
}
