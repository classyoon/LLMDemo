//
//  MainMenuView.swift
//  LLMDemo
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct MainMenuView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var apiKeys: [APIKeyStore]

    @State private var showSettings = false
    @State private var showNoAPIKeyAlert = false
    @State private var navigateToGame = false

    var gameManager: GameManager

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()

                // Title
                VStack(spacing: 10) {
                    Image(systemName: "figure.stand.line.dotted.figure.stand")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)

                    Text("Two Guards Riddle")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Can you figure out which guard I am?")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Description
                VStack(alignment: .leading, spacing: 10) {
                    Text("The Challenge:")
                        .font(.headline)

                    Text("One guard always tells the truth, the other always lies. Chat with the AI guard and try to figure out which one it is!")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)

                Spacer()

                // Buttons
                VStack(spacing: 15) {
                    Button(action: startNewGame) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("New Game")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }

                    Button(action: { showSettings = true }) {
                        HStack {
                            Image(systemName: "gearshape.fill")
                            Text("Settings")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .alert("API Key Required", isPresented: $showNoAPIKeyAlert) {
                Button("Go to Settings") {
                    showSettings = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please configure your API key in Settings before starting a game.")
            }
            .navigationDestination(isPresented: $navigateToGame) {
                GameView(gameManager: gameManager)
            }
        }
    }

    private func startNewGame() {
        // Check if API key exists
        guard let apiKey = apiKeys.first(where: { $0.provider == ProviderType.chatGPT.rawValue }) else {
            showNoAPIKeyAlert = true
            return
        }

        // Create and configure provider
        let provider = ProviderFactory.createProvider(type: .chatGPT)
        provider.configure(apiKey: apiKey.apiKey)

        // Start new game
        gameManager.startNewGame(provider: provider, context: modelContext)

        // Navigate to game
        navigateToGame = true
    }
}

#Preview {
    MainMenuView(gameManager: GameManager())
        .modelContainer(for: [APIKeyStore.self, ChatMessage.self, GameSession.self])
}
