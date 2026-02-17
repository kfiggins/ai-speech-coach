//
//  SessionStatus.swift
//  SpeechCoach
//
//  Created by AI Speech Coach
//

import Foundation

/// Represents the current status of the recording flow
enum SessionStatus: String {
    case idle = "Idle"
    case recording = "Recording"
    case ready = "Ready"

    var displayText: String {
        return self.rawValue
    }

    var isRecording: Bool {
        return self == .recording
    }

    var canStartRecording: Bool {
        return self == .idle || self == .ready
    }
}
