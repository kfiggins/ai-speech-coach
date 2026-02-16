//
//  SessionTests.swift
//  SpeechCoachTests
//
//  Created by AI Speech Coach
//

import XCTest
@testable import SpeechCoach

final class SessionTests: XCTestCase {

    func testSessionInitialization() {
        let session = Session()

        XCTAssertFalse(session.id.isEmpty)
        XCTAssertNotNil(session.createdAt)
        XCTAssertEqual(session.durationSeconds, 0)
        XCTAssertEqual(session.transcriptText, "")
        XCTAssertNil(session.stats)
    }

    func testSessionWithCustomID() {
        let customID = "test-session-123"
        let session = Session(id: customID)

        XCTAssertEqual(session.id, customID)
    }

    func testSessionFileURLs() {
        let session = Session(id: "test-123")

        let audioURL = session.audioFileURL
        let transcriptURL = session.transcriptFileURL

        XCTAssertTrue(audioURL.path().contains("test-123"))
        XCTAssertTrue(audioURL.path().contains("audio.m4a"))

        XCTAssertTrue(transcriptURL.path().contains("test-123"))
        XCTAssertTrue(transcriptURL.path().contains("transcript.txt"))
    }

    func testFormattedDate() {
        let date = Date()
        let session = Session(id: "test", createdAt: date)

        let formatted = session.formattedDate

        XCTAssertFalse(formatted.isEmpty)
        // Should contain date components
        XCTAssertTrue(formatted.count > 5)
    }

    func testSessionStats() {
        var session = Session()

        XCTAssertNil(session.stats)

        let stats = SessionStats(
            totalWords: 100,
            uniqueWords: 50,
            fillerWordCount: 5
        )
        session.stats = stats

        XCTAssertNotNil(session.stats)
        XCTAssertEqual(session.stats?.totalWords, 100)
        XCTAssertEqual(session.stats?.uniqueWords, 50)
        XCTAssertEqual(session.stats?.fillerWordCount, 5)
    }
}

// MARK: - Session Stats Tests

final class SessionStatsTests: XCTestCase {

    func testStatsInitialization() {
        let stats = SessionStats()

        XCTAssertEqual(stats.totalWords, 0)
        XCTAssertEqual(stats.uniqueWords, 0)
        XCTAssertEqual(stats.fillerWordCount, 0)
        XCTAssertTrue(stats.fillerWordBreakdown.isEmpty)
        XCTAssertTrue(stats.topWords.isEmpty)
        XCTAssertNil(stats.wordsPerMinute)
    }

    func testStatsWithValues() {
        let breakdown = ["um": 3, "uh": 2]
        let topWords = [
            WordCount(word: "test", count: 5),
            WordCount(word: "example", count: 3)
        ]

        let stats = SessionStats(
            totalWords: 100,
            uniqueWords: 75,
            fillerWordCount: 5,
            fillerWordBreakdown: breakdown,
            topWords: topWords,
            wordsPerMinute: 125.5
        )

        XCTAssertEqual(stats.totalWords, 100)
        XCTAssertEqual(stats.uniqueWords, 75)
        XCTAssertEqual(stats.fillerWordCount, 5)
        XCTAssertEqual(stats.fillerWordBreakdown.count, 2)
        XCTAssertEqual(stats.fillerWordBreakdown["um"], 3)
        XCTAssertEqual(stats.topWords.count, 2)
        XCTAssertEqual(stats.wordsPerMinute, 125.5)
    }
}

// MARK: - File Manager Tests

final class SessionFileManagerTests: XCTestCase {

    func testSessionDirectoryPath() {
        let sessionID = "test-session-456"
        let directory = SessionFileManager.sessionDirectory(for: sessionID)

        XCTAssertTrue(directory.path().contains("SpeechCoach"))
        XCTAssertTrue(directory.path().contains("Sessions"))
        XCTAssertTrue(directory.path().contains(sessionID))
    }

    func testAudioFileURL() {
        let sessionID = "test-audio"
        let audioURL = SessionFileManager.audioFileURL(for: sessionID)

        XCTAssertTrue(audioURL.path().contains(sessionID))
        XCTAssertTrue(audioURL.lastPathComponent == "audio.m4a")
    }

    func testTranscriptFileURL() {
        let sessionID = "test-transcript"
        let transcriptURL = SessionFileManager.transcriptFileURL(for: sessionID)

        XCTAssertTrue(transcriptURL.path().contains(sessionID))
        XCTAssertTrue(transcriptURL.lastPathComponent == "transcript.txt")
    }

    func testSessionsDirectoryIsInApplicationSupport() {
        let sessionsDir = SessionFileManager.sessionsDirectory

        // Verify it's a valid directory path
        XCTAssertFalse(sessionsDir.path().isEmpty)
        // Should contain SpeechCoach and Sessions
        XCTAssertTrue(sessionsDir.path().contains("SpeechCoach"))
        XCTAssertTrue(sessionsDir.path().contains("Sessions"))
    }
}
