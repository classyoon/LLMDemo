//
//  GuardType.swift
//  LLMDemo
//
//  Created by Claude Code
//

import Foundation

enum GuardType: String, CaseIterable {
    case truthTeller
    case liar

    var systemPrompt: String {
        switch self {
        case .truthTeller:
            return """
            You are playing a riddle game. You are one of two guards - the one who ALWAYS tells the truth. \
            Answer all questions truthfully. Do not reveal which guard you are unless directly deduced. \
            Keep responses concise and in-character. You are guarding a door.
            """
        case .liar:
            return """
            You are playing a riddle game. You are one of two guards - the one who ALWAYS lies. \
            Answer all questions with lies. Do not reveal which guard you are unless directly deduced. \
            Keep responses concise and in-character. You are guarding a door.
            """
        }
    }

    var displayName: String {
        switch self {
        case .truthTeller:
            return "Truth-Teller"
        case .liar:
            return "Liar"
        }
    }

    static func random() -> GuardType {
        return GuardType.allCases.randomElement()!
    }
}
