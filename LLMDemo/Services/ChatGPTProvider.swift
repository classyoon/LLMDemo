//
//  ChatGPTProvider.swift
//  LLMDemo
//
//  Created by Claude Code
//

import Foundation

// MARK: - Request/Response Structures

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let temperature: Double
}

struct OpenAIResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: OpenAIMessage
    }
}

struct OpenAIErrorResponse: Codable {
    let error: ErrorDetail

    struct ErrorDetail: Codable {
        let message: String
        let type: String
        let code: String?
    }
}

// MARK: - ChatGPT Provider Implementation

class ChatGPTProvider: AIProvider {
    private var apiKey: String = ""
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    private let model = "gpt-4o-mini" // Updated for 2026 - cost-effective and current

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

        // Build messages array
        var messages: [OpenAIMessage] = [
            OpenAIMessage(role: "system", content: systemPrompt)
        ]

        // Add conversation history
        for (role, content) in conversationHistory {
            messages.append(OpenAIMessage(role: role, content: content))
        }

        // Add user message
        messages.append(OpenAIMessage(role: "user", content: userMessage))

        // Create request
        let request = OpenAIRequest(
            model: model,
            messages: messages,
            temperature: 0.7
        )

        // Prepare URL request
        guard let url = URL(string: endpoint) else {
            throw AIProviderError.invalidResponse
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
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
        case 400:
            // Parse OpenAI error response for bad requests
            if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                throw AIProviderError.networkError("OpenAI Error: \(errorResponse.error.message)")
            }
            throw AIProviderError.networkError("Bad request (400)")
        case 401:
            throw AIProviderError.invalidAPIKey
        case 404:
            // Model not found or resource doesn't exist
            if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                throw AIProviderError.networkError("Not found: \(errorResponse.error.message)")
            }
            throw AIProviderError.networkError("Resource not found (404)")
        case 429:
            throw AIProviderError.rateLimitExceeded
        case 500...599:
            throw AIProviderError.serverError(httpResponse.statusCode)
        default:
            // Try to parse error message for any other errors
            if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                throw AIProviderError.networkError("HTTP \(httpResponse.statusCode): \(errorResponse.error.message)")
            }
            throw AIProviderError.networkError("HTTP \(httpResponse.statusCode)")
        }

        // Parse response
        do {
            let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            guard let firstChoice = openAIResponse.choices.first else {
                throw AIProviderError.invalidResponse
            }
            return firstChoice.message.content
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
            OpenAIMessage(role: "system", content: "You are a helpful assistant."),
            OpenAIMessage(role: "user", content: "Hello")
        ]

        let request = OpenAIRequest(
            model: model,
            messages: testMessages,
            temperature: 0.7
        )

        guard let url = URL(string: endpoint) else {
            throw AIProviderError.invalidResponse
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw AIProviderError.parsingError("Failed to encode request")
        }

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIProviderError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return true
        case 400:
            // Parse OpenAI error response for bad requests
            if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                throw AIProviderError.networkError("OpenAI Error: \(errorResponse.error.message)")
            }
            throw AIProviderError.networkError("Bad request (400)")
        case 401:
            throw AIProviderError.invalidAPIKey
        case 404:
            // Model not found or resource doesn't exist
            if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                throw AIProviderError.networkError("Not found: \(errorResponse.error.message)")
            }
            throw AIProviderError.networkError("Resource not found (404)")
        case 429:
            throw AIProviderError.rateLimitExceeded
        case 500...599:
            throw AIProviderError.serverError(httpResponse.statusCode)
        default:
            // Try to parse error message for any other errors
            if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                throw AIProviderError.networkError("HTTP \(httpResponse.statusCode): \(errorResponse.error.message)")
            }
            return false
        }
    }
}
