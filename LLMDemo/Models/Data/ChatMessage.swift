//
//  ChatMessage.swift
//  LLMDemo
//
//  Created by Claude Code
//

import Foundation
import SwiftData

@Model
final class ChatMessage {
    var id: UUID
    var role: String // "user" or "assistant"
    var content: String
    var timestamp: Date
    var gameSession: GameSession?

    init(role: String, content: String, gameSession: GameSession? = nil) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
        self.gameSession = gameSession
    }
}
