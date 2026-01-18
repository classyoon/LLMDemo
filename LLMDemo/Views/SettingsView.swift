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
    @State private var isTesting: Bool = false
    @State private var saveMessage: String?
    @State private var showSaveAlert: Bool = false
    @State private var testMessage: String?
    @State private var showTestAlert: Bool = false

    var body: some View {
        NavigationView {
            Form {
                Section("Provider Selection") {
                    Picker("AI Provider", selection: $selectedProvider) {
                        ForEach(ProviderType.allCases, id: \.self) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }
                    .onChange(of: selectedProvider) { _, _ in
                        loadExistingKey()
                    }
                }

                Section("API Key") {
                    SecureField("Enter API Key", text: $apiKeyInput)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Button(action: saveAPIKey) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Save API Key")
                        }
                    }
                    .disabled(apiKeyInput.isEmpty)

                    Button(action: testAPIKey) {
                        HStack {
                            if isTesting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("Testing...")
                            } else {
                                Image(systemName: "checkmark.circle")
                                Text("Test API Key")
                            }
                        }
                    }
                    .disabled(!hasSavedKey || isTesting)
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
            .alert("Saved", isPresented: $showSaveAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                if let message = saveMessage {
                    Text(message)
                }
            }
            .alert("Test Result", isPresented: $showTestAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                if let message = testMessage {
                    Text(message)
                }
            }
            .onAppear {
                loadExistingKey()
            }
        }
    }

    private var hasSavedKey: Bool {
        return apiKeys.contains(where: { $0.provider == selectedProvider.rawValue })
    }

    private func loadExistingKey() {
        if let existingKey = apiKeys.first(where: { $0.provider == selectedProvider.rawValue }) {
            apiKeyInput = existingKey.apiKey
        } else {
            apiKeyInput = ""
        }
    }

    private func saveAPIKey() {
        // Save or update API key immediately without validation
        if let existingKey = apiKeys.first(where: { $0.provider == selectedProvider.rawValue }) {
            existingKey.updateKey(apiKeyInput)
        } else {
            let newKey = APIKeyStore(provider: selectedProvider.rawValue, apiKey: apiKeyInput)
            modelContext.insert(newKey)
        }

        do {
            try modelContext.save()
            saveMessage = "API key saved successfully! You can now test it to verify it works."
            showSaveAlert = true
        } catch {
            saveMessage = "Failed to save API key: \(error.localizedDescription)"
            showSaveAlert = true
        }
    }

    private func testAPIKey() {
        guard let savedKey = apiKeys.first(where: { $0.provider == selectedProvider.rawValue }) else {
            testMessage = "No API key found. Please save a key first."
            showTestAlert = true
            return
        }

        isTesting = true
        testMessage = nil

        Task {
            do {
                let provider = ProviderFactory.createProvider(type: selectedProvider)
                provider.configure(apiKey: savedKey.apiKey)

                let isValid = try await provider.validateAPIKey()

                await MainActor.run {
                    if isValid {
                        testMessage = "API key is valid and working!"
                    } else {
                        testMessage = "API key validation failed. The key may be invalid."
                    }

                    isTesting = false
                    showTestAlert = true
                }
            } catch {
                await MainActor.run {
                    if let apiError = error as? AIProviderError {
                        testMessage = apiError.errorDescription
                    } else {
                        testMessage = "Error testing key: \(error.localizedDescription)"
                    }
                    isTesting = false
                    showTestAlert = true
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
