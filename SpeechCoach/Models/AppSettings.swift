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

    @Published var coachingModel: String {
        didSet { UserDefaults.standard.set(coachingModel, forKey: "coachingModel") }
    }

    @Published var coachingStyle: String {
        didSet { UserDefaults.standard.set(coachingStyle, forKey: "coachingStyle") }
    }

    @Published var speechGoal: String {
        didSet { UserDefaults.standard.set(speechGoal, forKey: "speechGoal") }
    }

    @Published var targetAudience: String {
        didSet { UserDefaults.standard.set(targetAudience, forKey: "targetAudience") }
    }

    init() {
        // Load transcription model
        if let raw = UserDefaults.standard.string(forKey: "transcriptionModel"),
           let model = OpenAITranscriptionService.TranscriptionModel(rawValue: raw) {
            self.transcriptionModel = model
        } else {
            self.transcriptionModel = .gpt4oTranscribe
        }

        // Load coaching model (will be typed properly in Phase 10)
        self.coachingModel = UserDefaults.standard.string(forKey: "coachingModel") ?? "gpt-4.1"

        // Load coaching style
        self.coachingStyle = UserDefaults.standard.string(forKey: "coachingStyle") ?? "supportive"

        // Load speech goal and target audience
        self.speechGoal = UserDefaults.standard.string(forKey: "speechGoal") ?? ""
        self.targetAudience = UserDefaults.standard.string(forKey: "targetAudience") ?? ""
    }
}
