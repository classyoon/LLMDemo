//
//  LLMService.swift
//  JobApplication
//

import Foundation

// MARK: - Protocol

protocol LLMService {
    var name: String { get }
    func summarize(content: String) async throws -> String
}

// MARK: - Errors

enum LLMServiceError: LocalizedError {
    case invalidAPIKey
    case networkError(Error)
    case invalidResponse
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid or missing API key"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from API"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}

// MARK: - LLM Provider Enum

enum LLMProvider: String, CaseIterable, Identifiable {
    case claude = "Claude"
    case gemini = "Gemini"

    var id: String { rawValue }
}

// MARK: - Claude Service

class ClaudeService: LLMService {
    let name = "Claude"
    private let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func summarize(content: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw LLMServiceError.invalidAPIKey
        }

        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let truncatedContent = String(content.prefix(50000))

        let body: [String: Any] = [
            "model": "claude-3-haiku-20240307",
            "max_tokens": 1024,
            "messages": [
                [
                    "role": "user",
                    "content": """
                    Please provide a brief summary of this company based on the following webpage content. \
                    Focus on what the company does, their products/services, and any notable information. \
                    Keep the summary concise (2-3 paragraphs).

                    Content:
                    \(truncatedContent)
                    """
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMServiceError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw LLMServiceError.apiError(message)
            }
            throw LLMServiceError.apiError("HTTP \(httpResponse.statusCode)")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let contentArray = json["content"] as? [[String: Any]],
              let firstContent = contentArray.first,
              let text = firstContent["text"] as? String else {
            throw LLMServiceError.invalidResponse
        }

        return text
    }
}

// MARK: - Gemini Service

class GeminiService: LLMService {
    let name = "Gemini"
    private let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func summarize(content: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw LLMServiceError.invalidAPIKey
        }

        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw LLMServiceError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let truncatedContent = String(content.prefix(50000))

        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "text": """
                            Please provide a brief summary of this company based on the following webpage content. \
                            Focus on what the company does, their products/services, and any notable information. \
                            Keep the summary concise (2-3 paragraphs).

                            Content:
                            \(truncatedContent)
                            """
                        ]
                    ]
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMServiceError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw LLMServiceError.apiError(message)
            }
            throw LLMServiceError.apiError("HTTP \(httpResponse.statusCode)")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw LLMServiceError.invalidResponse
        }

        return text
    }
}
