//
//  ProviderFactory.swift
//  LLMDemo
//
//  Created by Claude Code
//

import Foundation

enum ProviderType: String, CaseIterable {
    case claude = "Claude"
    case chatGPT = "ChatGPT"

    var displayName: String {
        return rawValue
    }

    static var defaultProvider: ProviderType {
        return .claude
    }
}

class ProviderFactory {
    static func createProvider(type: ProviderType) -> AIProvider {
        switch type {
        case .claude:
            return ClaudeProvider()
        case .chatGPT:
            return ChatGPTProvider()
        }
    }
}
