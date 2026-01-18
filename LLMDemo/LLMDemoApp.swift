//
//  LLMDemoApp.swift
//  LLMDemo
//
//  Created by Conner Yoon on 1/17/26.
//

import SwiftUI
import SwiftData

@main
struct LLMDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [APIKeyStore.self, ChatMessage.self, GameSession.self])
    }
}
