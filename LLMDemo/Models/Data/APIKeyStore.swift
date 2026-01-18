//
//  APIKeyStore.swift
//  LLMDemo
//
//  Created by Claude Code
//

import Foundation
import SwiftData

@Model
final class APIKeyStore {
    @Attribute(.unique) var provider: String
    var apiKey: String
    var createdAt: Date
    var lastModified: Date

    init(provider: String, apiKey: String) {
        self.provider = provider
        self.apiKey = apiKey
        self.createdAt = Date()
        self.lastModified = Date()
    }

    func updateKey(_ newKey: String) {
        self.apiKey = newKey
        self.lastModified = Date()
    }
}
