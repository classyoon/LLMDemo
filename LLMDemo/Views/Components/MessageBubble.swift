//
//  MessageBubble.swift
//  LLMDemo
//
//  Created by Claude Code
//

import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == "user" {
                Spacer()
            }

            VStack(alignment: message.role == "user" ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(message.role == "user" ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.role == "user" ? .white : .primary)
                    .cornerRadius(16)

                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
            }

            if message.role == "assistant" {
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

#Preview {
    VStack {
        MessageBubble(message: ChatMessage(role: "user", content: "Are you the truth-teller?"))
        MessageBubble(message: ChatMessage(role: "assistant", content: "I am one of the two guards. What would you like to know?"))
    }
}
