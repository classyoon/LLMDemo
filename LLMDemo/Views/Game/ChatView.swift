//
//  ChatView.swift
//  LLMDemo
//
//  Created by Claude Code
//

import SwiftUI

struct ChatView: View {
    @Binding var messages: [ChatMessage]
    var isProcessing: Bool

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(messages, id: \.id) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }

                    if isProcessing {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("Guard is typing...")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .id("processing")
                    }
                }
                .padding(.top, 8)
            }
            .onChange(of: messages.count) { _, _ in
                withAnimation {
                    if let lastMessage = messages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: isProcessing) { _, newValue in
                if newValue {
                    withAnimation {
                        proxy.scrollTo("processing", anchor: .bottom)
                    }
                }
            }
        }
    }
}

#Preview {
    ChatView(
        messages: .constant([
            ChatMessage(role: "user", content: "Are you the truth-teller?"),
            ChatMessage(role: "assistant", content: "I am one of the two guards guarding the door.")
        ]),
        isProcessing: false
    )
}
