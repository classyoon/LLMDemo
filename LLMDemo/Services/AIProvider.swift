//
//  AIProvider.swift
//  LLMDemo
//
//  Created by Claude Code
//

import Foundation

enum AIProviderError: Error, LocalizedError {
    case invalidAPIKey
    case networkError(String)
    case rateLimitExceeded
    case parsingError(String)
    case invalidResponse
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key. Please check your API key in Settings."
        case .networkError(let message):
            return "Network error: \(message)"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please wait a moment and try again."
        case .parsingError(let message):
            return "Error parsing response: \(message)"
        case .invalidResponse:
            return "Received invalid response from API."
        case .serverError(let code):
            return "Server error (code \(code)). Please try again later."
        }
    }
}

protocol AIProvider {
    func configure(apiKey: String)
    func sendMessage(
        systemPrompt: String,
        conversationHistory: [(role: String, content: String)],
        userMessage: String
    ) async throws -> String
    func validateAPIKey() async throws -> Bool
}
