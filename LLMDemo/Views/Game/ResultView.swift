//
//  ResultView.swift
//  LLMDemo
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct ResultView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var gameManager: GameManager

    private var isCorrect: Bool {
        if case .gameOver(let result) = gameManager.currentState {
            return result
        }
        return false
    }

    private var actualGuard: GuardType? {
        return gameManager.getActualGuardType()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Result Icon
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(isCorrect ? .green : .red)

                // Result Text
                VStack(spacing: 10) {
                    Text(isCorrect ? "Correct!" : "Incorrect!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                   
                    if let guardman = actualGuard {
                        Text("The guard was the \(guardman.displayName)")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }

                // Conversation Summary
                VStack(alignment: .leading, spacing: 12) {
                    Text("Conversation History")
                        .font(.headline)

                    Text("You exchanged \(gameManager.messages.count) messages")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Divider()

                    // Display all messages
                    ForEach(gameManager.messages, id: \.id) { message in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(message.role == "user" ? "You:" : "Guard:")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(message.role == "user" ? .blue : .green)

                            Text(message.content)
                                .font(.body)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Action Buttons
                VStack(spacing: 15) {
                    Button(action: playAgain) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Play Again")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }

                    Button(action: goToMainMenu) {
                        HStack {
                            Image(systemName: "house.fill")
                            Text("Main Menu")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Game Over")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }

    private func playAgain() {
        // Reset game and pop back to main menu, then start new game
        gameManager.resetGame()
        dismiss()
    }

    private func goToMainMenu() {
        // Reset game and pop back to main menu
        gameManager.resetGame()
        dismiss()
    }
}

#Preview {
    let manager = GameManager()
    manager.currentState = .gameOver(true)

    return NavigationStack {
        ResultView(gameManager: manager)
            .modelContainer(for: [APIKeyStore.self, ChatMessage.self, GameSession.self])
    }
}
