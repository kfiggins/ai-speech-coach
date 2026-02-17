//
//  AppSettings.swift
//  SpeechCoach
//
//  Created by AI Speech Coach
//

import Foundation

/// Centralized settings model for non-secret preferences (stored in UserDefaults)
class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var transcriptionModel: OpenAITranscriptionService.TranscriptionModel {
        didSet { UserDefaults.standard.set(transcriptionModel.rawValue, forKey: "transcriptionModel") }
    }

    @Published var coachingModel: CoachingService.CoachingModel {
        didSet { UserDefaults.standard.set(coachingModel.rawValue, forKey: "coachingModel") }
    }

    @Published var coachingStyle: CoachingService.CoachingStyle {
        didSet { UserDefaults.standard.set(coachingStyle.rawValue, forKey: "coachingStyle") }
    }

    @Published var speechGoal: String {
        didSet { UserDefaults.standard.set(speechGoal, forKey: "speechGoal") }
    }

    @Published var targetAudience: String {
        didSet { UserDefaults.standard.set(targetAudience, forKey: "targetAudience") }
    }

    /// Cached Keychain check — read once at init, updated on save/delete
    @Published var hasAPIKey: Bool = false

    private let keychain = KeychainService()

    /// Call after saving or deleting the API key to update the cached flag
    func refreshAPIKeyStatus() {
        hasAPIKey = keychain.hasOpenAIKey
    }

    init() {
        // Load transcription model
        if let raw = UserDefaults.standard.string(forKey: "transcriptionModel"),
           let model = OpenAITranscriptionService.TranscriptionModel(rawValue: raw) {
            self.transcriptionModel = model
        } else {
            self.transcriptionModel = .gpt4oTranscribe
        }

        // Load coaching model
        if let raw = UserDefaults.standard.string(forKey: "coachingModel"),
           let model = CoachingService.CoachingModel(rawValue: raw) {
            self.coachingModel = model
        } else {
            self.coachingModel = .gpt4_1
        }

        // Load coaching style
        if let raw = UserDefaults.standard.string(forKey: "coachingStyle"),
           let style = CoachingService.CoachingStyle(rawValue: raw) {
            self.coachingStyle = style
        } else {
            self.coachingStyle = .supportive
        }

        // Load speech goal and target audience
        self.speechGoal = UserDefaults.standard.string(forKey: "speechGoal") ?? ""
        self.targetAudience = UserDefaults.standard.string(forKey: "targetAudience") ?? ""
    }
}
