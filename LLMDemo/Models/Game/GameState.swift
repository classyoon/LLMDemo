//
//  GameState.swift
//  LLMDemo
//
//  Created by Claude Code
//

import Foundation

enum GameState: Equatable {
    case notStarted
    case settingUp
    case playing
    case gameOver(Bool) // Bool indicates if guess was correct

    static func == (lhs: GameState, rhs: GameState) -> Bool {
        switch (lhs, rhs) {
        case (.notStarted, .notStarted),
             (.settingUp, .settingUp),
             (.playing, .playing):
            return true
        case (.gameOver(let lhsResult), .gameOver(let rhsResult)):
            return lhsResult == rhsResult
        default:
            return false
        }
    }
}
