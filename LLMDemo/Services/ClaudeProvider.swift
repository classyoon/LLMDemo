//
//  ClaudeProvider.swift
//  LLMDemo
//
//  Created by Claude Code
//

import Foundation

// MARK: - Request/Response Structures

struct ClaudeMessage: Codable {
    let role: String
    let content: String
}

struct ClaudeRequest: Codable {
    let model: String
    let max_tokens: Int
    let system: String
    let messages: [ClaudeMessage]
}

struct ClaudeResponse: Codable {
    let content: [ContentBlock]

    struct ContentBlock: Codable {
        let type: String
        let text: String?
    }
}

// MARK: - Claude Provider Implementation

class ClaudeProvider: AIProvider {
    private var apiKey: String = ""
    private let endpoint = "https://api.anthropic.com/v1/messages"
    private let model = "claude-3-haiku-20240307"
    private let anthropicVersion = "2023-06-01"

    func configure(apiKey: String) {
        self.apiKey = apiKey
    }

    func sendMessage(
        systemPrompt: String,
        conversationHistory: [(role: String, content: String)],
        userMessage: String
    ) async throws -> String {
        guard !apiKey.isEmpty else {
            throw AIProviderError.invalidAPIKey
        }

        // Build messages array (Claude uses "user" and "assistant" roles)
        var messages: [ClaudeMessage] = []

        // Add conversation history
        for (role, content) in conversationHistory {
            // Map roles appropriately (Claude uses "user" and "assistant")
            let claudeRole = role == "assistant" ? "assistant" : "user"
            messages.append(ClaudeMessage(role: claudeRole, content: content))
        }

        // Add user message
        messages.append(ClaudeMessage(role: "user", content: userMessage))

        // Create request (Claude uses system as a separate field)
        let request = ClaudeRequest(
            model: model,
            max_tokens: 1024,
            system: systemPrompt,
            messages: messages
        )

        // Prepare URL request
        guard let url = URL(string: endpoint) else {
            throw AIProviderError.invalidResponse
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue(anthropicVersion, forHTTPHeaderField: "anthropic-version")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw AIProviderError.parsingError("Failed to encode request: \(error.localizedDescription)")
        }

        // Send request
        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        // Check HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIProviderError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw AIProviderError.invalidAPIKey
        case 429:
            throw AIProviderError.rateLimitExceeded
        case 500...599:
            throw AIProviderError.serverError(httpResponse.statusCode)
        default:
            throw AIProviderError.networkError("HTTP \(httpResponse.statusCode)")
        }

        // Parse response
        do {
            let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)
            guard let firstContent = claudeResponse.content.first,
                  let text = firstContent.text else {
                throw AIProviderError.invalidResponse
            }
            return text
        } catch {
            throw AIProviderError.parsingError("Failed to decode response: \(error.localizedDescription)")
        }
    }

    func validateAPIKey() async throws -> Bool {
        guard !apiKey.isEmpty else {
            throw AIProviderError.invalidAPIKey
        }

        // Send a minimal request to validate the API key
        let testMessages = [
            ClaudeMessage(role: "user", content: "Hello")
        ]

        let request = ClaudeRequest(
            model: model,
            max_tokens: 10,
            system: "You are a helpful assistant.",
            messages: testMessages
        )

        guard let url = URL(string: endpoint) else {
            throw AIProviderError.invalidResponse
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue(anthropicVersion, forHTTPHeaderField: "anthropic-version")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw AIProviderError.parsingError("Failed to encode request")
        }

        let (_, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIProviderError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw AIProviderError.invalidAPIKey
        }

        return httpResponse.statusCode == 200
    }
}
