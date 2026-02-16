//
//  Session.swift
//  SpeechCoach
//
//  Created by AI Speech Coach
//

import Foundation

/// Represents a recording session with transcript and analytics
struct Session: Identifiable, Equatable {
    let id: String
    let createdAt: Date
    var durationSeconds: Double
    var transcriptText: String
    var stats: SessionStats?

    static func == (lhs: Session, rhs: Session) -> Bool {
        lhs.id == rhs.id
    }

    init(id: String = UUID().uuidString, createdAt: Date = Date()) {
        self.id = id
        self.createdAt = createdAt
        self.durationSeconds = 0
        self.transcriptText = ""
        self.stats = nil
    }

    /// URL to the audio file for this session
    var audioFileURL: URL {
        SessionFileManager.audioFileURL(for: id)
    }

    /// URL to the transcript file for this session
    var transcriptFileURL: URL {
        SessionFileManager.transcriptFileURL(for: id)
    }

    /// Formatted date string for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}

/// Statistics for a session
struct SessionStats: Equatable {
    let totalWords: Int
    let uniqueWords: Int
    let fillerWordCount: Int
    let fillerWordBreakdown: [String: Int]
    let topWords: [WordCount]
    let wordsPerMinute: Double?

    init(
        totalWords: Int = 0,
        uniqueWords: Int = 0,
        fillerWordCount: Int = 0,
        fillerWordBreakdown: [String: Int] = [:],
        topWords: [WordCount] = [],
        wordsPerMinute: Double? = nil
    ) {
        self.totalWords = totalWords
        self.uniqueWords = uniqueWords
        self.fillerWordCount = fillerWordCount
        self.fillerWordBreakdown = fillerWordBreakdown
        self.topWords = topWords
        self.wordsPerMinute = wordsPerMinute
    }
}

/// Word and its occurrence count
struct WordCount: Identifiable, Equatable {
    let id = UUID()
    let word: String
    let count: Int

    static func == (lhs: WordCount, rhs: WordCount) -> Bool {
        lhs.word == rhs.word && lhs.count == rhs.count
    }
}

/// Helper for managing session file paths
struct SessionFileManager {
    static var sessionsDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("SpeechCoach/Sessions")
    }

    static func sessionDirectory(for sessionId: String) -> URL {
        sessionsDirectory.appendingPathComponent(sessionId)
    }

    static func audioFileURL(for sessionId: String) -> URL {
        sessionDirectory(for: sessionId).appendingPathComponent("audio.m4a")
    }

    static func transcriptFileURL(for sessionId: String) -> URL {
        sessionDirectory(for: sessionId).appendingPathComponent("transcript.txt")
    }
}
