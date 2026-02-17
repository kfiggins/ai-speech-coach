//
//  CoachingResult.swift
//  SpeechCoach
//
//  Created by AI Speech Coach
//

import Foundation

/// Complete coaching analysis result from LLM
struct CoachingResult: Codable, Equatable {
    let scores: CoachingScores
    let metrics: CoachingMetrics
    let highlights: [CoachingHighlight]
    let actionPlan: [String]
    let rewrite: CoachingRewrite?
    let raw: String?
}

/// Scoring breakdown for speech quality (1-10 scale)
struct CoachingScores: Codable, Equatable {
    let clarity: Int
    let confidence: Int
    let conciseness: Int
    let structure: Int
    let persuasion: Int

    var overall: Double {
        Double(clarity + confidence + conciseness + structure + persuasion) / 5.0
    }

    enum CodingKeys: String, CodingKey {
        case clarity, confidence, conciseness, structure, persuasion
    }
}

/// Quantitative metrics extracted from the speech
struct CoachingMetrics: Codable, Equatable {
    let durationSeconds: Double?
    let estimatedWPM: Int?
    let fillerWords: [String: Int]?
    let repeatPhrases: [String]?
}

/// A highlighted strength or area for improvement
struct CoachingHighlight: Codable, Equatable {
    let type: HighlightType
    let text: String

    enum HighlightType: String, Codable, Equatable {
        case strength
        case improvement
    }
}

/// Suggested rewrite of the speech
struct CoachingRewrite: Codable, Equatable {
    let version: String
    let text: String
}
