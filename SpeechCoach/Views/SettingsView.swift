//
//  SettingsView.swift
//  SpeechCoach
//
//  Created by AI Speech Coach
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var appSettings: AppSettings

    @State private var apiKeyInput = ""
    @State private var hasKey = false
    @State private var showingAPIKey = false
    @State private var saveError: String?

    private let keychain = KeychainService()

    init(appSettings: AppSettings = AppSettings.shared) {
        self.appSettings = appSettings
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()

            Divider()

            Form {
                // MARK: - API Key Section
                Section {
                    HStack {
                        if showingAPIKey {
                            TextField("sk-...", text: $apiKeyInput)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            SecureField("sk-...", text: $apiKeyInput)
                                .textFieldStyle(.roundedBorder)
                        }

                        Button(action: { showingAPIKey.toggle() }) {
                            Image(systemName: showingAPIKey ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.borderless)

                        Button("Save") { saveAPIKey() }
                            .buttonStyle(.bordered)
                            .disabled(apiKeyInput.isEmpty)
                    }

                    HStack(spacing: 6) {
                        if hasKey {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("API key configured")
                                .foregroundColor(.secondary)
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("No API key configured")
                                .foregroundColor(.secondary)
                        }
                    }
                    .font(.caption)

                    if let error = saveError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                } header: {
                    Text("OpenAI API Key")
                }

                // MARK: - Transcription Section
                Section {
                    Picker("Model", selection: $appSettings.transcriptionModel) {
                        ForEach(OpenAITranscriptionService.TranscriptionModel.allCases, id: \.self) { model in
                            Text(model.displayName).tag(model)
                        }
                    }
                } header: {
                    Text("Transcription")
                }

                // MARK: - Coaching Section
                Section {
                    Picker("Model", selection: $appSettings.coachingModel) {
                        ForEach(CoachingService.CoachingModel.allCases, id: \.self) { model in
                            Text(model.displayName).tag(model)
                        }
                    }

                    Picker("Style", selection: $appSettings.coachingStyle) {
                        ForEach(CoachingService.CoachingStyle.allCases, id: \.self) { style in
                            Text(style.displayName).tag(style)
                        }
                    }

                    TextField("Speech goal (optional)", text: $appSettings.speechGoal)
                    TextField("Target audience (optional)", text: $appSettings.targetAudience)
                } header: {
                    Text("Coaching")
                }

                // MARK: - Privacy Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Audio is sent to OpenAI for transcription and coaching analysis.", systemImage: "cloud")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Label("Your API key is stored securely in the macOS Keychain.", systemImage: "lock.shield")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Privacy")
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 450, height: 500)
        .onAppear {
            hasKey = keychain.hasOpenAIKey
        }
    }

    private func saveAPIKey() {
        saveError = nil
        do {
            let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                try keychain.delete(key: .openAIAPIKey)
                hasKey = false
            } else {
                try keychain.save(key: .openAIAPIKey, value: trimmed)
                hasKey = true
            }
            apiKeyInput = ""
        } catch {
            saveError = error.localizedDescription
        }
    }
}

#Preview {
    SettingsView()
}
