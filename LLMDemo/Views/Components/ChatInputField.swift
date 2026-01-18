//
//  ChatInputField.swift
//  LLMDemo
//
//  Created by Claude Code
//

import SwiftUI

struct ChatInputField: View {
    @Binding var text: String
    var isEnabled: Bool
    var onSend: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            TextField("Type your message...", text: $text, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(1...5)
                .disabled(!isEnabled)
                .onSubmit {
                    if canSend {
                        onSend()
                    }
                }

            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(canSend ? .blue : .gray)
            }
            .disabled(!canSend)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    private var canSend: Bool {
        isEnabled && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

#Preview {
    VStack {
        ChatInputField(text: .constant(""), isEnabled: true) {
            print("Send tapped")
        }

        ChatInputField(text: .constant("Sample message"), isEnabled: true) {
            print("Send tapped")
        }

        ChatInputField(text: .constant("Sample message"), isEnabled: false) {
            print("Send tapped")
        }
    }
}
