//
//  ProviderFactory.swift
//  LLMDemo
//
//  Created by Claude Code
//

import Foundation

enum ProviderType: String, CaseIterable {
    case chatGPT = "ChatGPT"

    var displayName: String {
        return rawValue
    }
}

class ProviderFactory {
    static func createProvider(type: ProviderType) -> AIProvider {
        switch type {
        case .chatGPT:
            return ChatGPTProvider()
        }
    }
}
