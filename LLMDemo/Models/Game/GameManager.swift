//
//  GameManager.swift
//  LLMDemo
//
//  Created by Claude Code
//

import Foundation
import SwiftData
import Observation

@Observable
class GameManager {
    var currentState: GameState = .notStarted
    var messages: [ChatMessage] = []
    var isProcessing: Bool = false
    var errorMessage: String?

    private var aiProvider: AIProvider?
    private var currentGuardType: GuardType?
    private var currentSession: GameSession?

    func startNewGame(provider: AIProvider, context: ModelContext) {
        currentState = .settingUp

        // Randomly select guard type
        let guardType = GuardType.random()
        currentGuardType = guardType

        // Create new game session
        let session = GameSession(guardType: guardType.rawValue)
        context.insert(session)
        currentSession = session

        // Configure provider
        aiProvider = provider

        // Clear messages and errors
        messages = []
        errorMessage = nil

        // Start game
        currentState = .playing
    }

    func sendMessage(_ message: String, context: ModelContext) async {
        guard let provider = aiProvider,
              let guardType = currentGuardType,
              let session = currentSession,
              !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        isProcessing = true
        errorMessage = nil

        // Create and save user message
        let userMessage = ChatMessage(role: "user", content: message, gameSession: session)
        context.insert(userMessage)
        messages.append(userMessage)

        // Build conversation history
        let history: [(role: String, content: String)] = messages.map { ($0.role, $0.content) }

        do {
            // Get AI response
            let response = try await provider.sendMessage(
                systemPrompt: guardType.systemPrompt,
                conversationHistory: history.dropLast(), // Exclude the just-added user message
                userMessage: message
            )

            // Create and save assistant message
            let assistantMessage = ChatMessage(role: "assistant", content: response, gameSession: session)
            context.insert(assistantMessage)
            messages.append(assistantMessage)

            // Save context
            try context.save()

        } catch let error as AIProviderError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
        }

        isProcessing = false
    }

    func makeGuess(_ guess: GuardType, context: ModelContext) {
        guard let actualGuard = currentGuardType,
              let session = currentSession else {
            return
        }

        // Record the guess
        session.completeGame(playerGuess: guess.rawValue)

        // Save context to persist game results
        do {
            try context.save()
        } catch {
            errorMessage = "Failed to save game result: \(error.localizedDescription)"
        }

        // Determine if guess was correct
        let isCorrect = (guess == actualGuard)
        currentState = .gameOver(isCorrect)
    }

    func resetGame() {
        currentState = .notStarted
        messages = []
        aiProvider = nil
        currentGuardType = nil
        currentSession = nil
        errorMessage = nil
        isProcessing = false
    }

    // Getter for the actual guard type (for result display)
    func getActualGuardType() -> GuardType? {
        return currentGuardType
    }

    // Check if game is ready to accept guess
    func canMakeGuess() -> Bool {
        return currentState == .playing && !messages.isEmpty && !isProcessing
    }
}
