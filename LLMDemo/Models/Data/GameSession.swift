//
//  GameSession.swift
//  LLMDemo
//
//  Created by Claude Code
//

import Foundation
import SwiftData

@Model
final class GameSession {
    var id: UUID
    var guardType: String // "truthTeller" or "liar"
    var playerGuess: String? // Player's guess: "truthTeller" or "liar"
    var isCorrect: Bool?
    var startedAt: Date
    var endedAt: Date?
    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.gameSession)
    var messages: [ChatMessage]

    init(guardType: String) {
        self.id = UUID()
        self.guardType = guardType
        self.startedAt = Date()
        self.messages = []
    }

    func completeGame(playerGuess: String) {
        self.playerGuess = playerGuess
        self.isCorrect = (playerGuess == guardType)
        self.endedAt = Date()
    }
}
