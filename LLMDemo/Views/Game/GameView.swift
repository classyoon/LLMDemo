//
//  GameView.swift
//  LLMDemo
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct GameView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var messageInput: String = ""
    @State private var showGuessDialog: Bool = false
    @State private var navigateToResult: Bool = false

    var gameManager: GameManager

    var body: some View {
        VStack(spacing: 0) {
            // Header with guess button
            HStack {
                Text("Chat with the Guard")
                    .font(.headline)

                Spacer()

                Button(action: { showGuessDialog = true }) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                        Text("Make Your Guess")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(!gameManager.canMakeGuess())
            }
            .padding()
            .background(Color(.systemGray6))

            // Error message if any
            if let errorMessage = gameManager.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding()
                .background(Color.red.opacity(0.1))
            }

            // Chat area
            ChatView(messages: $gameManager.messages, isProcessing: gameManager.isProcessing)

            // Input field
            ChatInputField(
                text: $messageInput,
                isEnabled: !gameManager.isProcessing && gameManager.currentState == .playing
            ) {
                sendMessage()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Which guard am I?", isPresented: $showGuessDialog, titleVisibility: .visible) {
            Button("Truth-Teller") {
                makeGuess(.truthTeller)
            }
            Button("Liar") {
                makeGuess(.liar)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Select which guard you think the AI is playing:")
        }
        .navigationDestination(isPresented: $navigateToResult) {
            ResultView(gameManager: gameManager)
        }
        .onChange(of: gameManager.currentState) { _, newState in
            if case .gameOver = newState {
                navigateToResult = true
            }
        }
    }

    private func sendMessage() {
        let message = messageInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }

        messageInput = ""

        Task {
            await gameManager.sendMessage(message, context: modelContext)
        }
    }

    private func makeGuess(_ guess: GuardType) {
        gameManager.makeGuess(guess)
    }
}

#Preview {
    NavigationStack {
        GameView(gameManager: GameManager())
            .modelContainer(for: [APIKeyStore.self, ChatMessage.self, GameSession.self])
    }
}
