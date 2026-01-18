//
//  SettingsView.swift
//  LLMDemo
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var apiKeys: [APIKeyStore]

    @State private var selectedProvider: ProviderType = .chatGPT
    @State private var apiKeyInput: String = ""
    @State private var isValidating: Bool = false
    @State private var validationMessage: String?
    @State private var showValidationAlert: Bool = false

    var body: some View {
        NavigationView {
            Form {
                Section("Provider Selection") {
                    Picker("AI Provider", selection: $selectedProvider) {
                        ForEach(ProviderType.allCases, id: \.self) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }
                }

                Section("API Key") {
                    TextField("Enter API Key", text: $apiKeyInput)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Button(action: saveAPIKey) {
                        HStack {
                            if isValidating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("Validating...")
                            } else {
                                Text("Save API Key")
                            }
                        }
                    }
                    .disabled(apiKeyInput.isEmpty || isValidating)
                }

                if !apiKeys.isEmpty {
                    Section("Saved API Keys") {
                        ForEach(apiKeys) { key in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(key.provider)
                                        .font(.headline)
                                    Text("Last modified: \(key.lastModified.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Text("••••••••")
                                    .foregroundColor(.gray)
                            }
                        }
                        .onDelete(perform: deleteAPIKeys)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Validation Result", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {
                    if validationMessage?.contains("successfully") == true {
                        dismiss()
                    }
                }
            } message: {
                if let message = validationMessage {
                    Text(message)
                }
            }
            .onAppear {
                loadExistingKey()
            }
        }
    }

    private func loadExistingKey() {
        if let existingKey = apiKeys.first(where: { $0.provider == selectedProvider.rawValue }) {
            apiKeyInput = existingKey.apiKey
        }
    }

    private func saveAPIKey() {
        isValidating = true
        validationMessage = nil

        Task {
            do {
                let provider = ProviderFactory.createProvider(type: selectedProvider)
                provider.configure(apiKey: apiKeyInput)

                let isValid = try await provider.validateAPIKey()

                await MainActor.run {
                    if isValid {
                        // Save or update API key
                        if let existingKey = apiKeys.first(where: { $0.provider == selectedProvider.rawValue }) {
                            existingKey.updateKey(apiKeyInput)
                        } else {
                            let newKey = APIKeyStore(provider: selectedProvider.rawValue, apiKey: apiKeyInput)
                            modelContext.insert(newKey)
                        }

                        try? modelContext.save()

                        validationMessage = "API key saved successfully!"
                    } else {
                        validationMessage = "API key validation failed. Please check your key."
                    }

                    isValidating = false
                    showValidationAlert = true
                }
            } catch {
                await MainActor.run {
                    if let apiError = error as? AIProviderError {
                        validationMessage = apiError.errorDescription
                    } else {
                        validationMessage = "Error: \(error.localizedDescription)"
                    }
                    isValidating = false
                    showValidationAlert = true
                }
            }
        }
    }

    private func deleteAPIKeys(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(apiKeys[index])
        }
        try? modelContext.save()
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [APIKeyStore.self])
}
