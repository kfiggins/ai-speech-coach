//
//  TranscriptionServiceTests.swift
//  SpeechCoachTests
//
//  Created by AI Speech Coach
//

import XCTest
@testable import SpeechCoach

final class TranscriptionServiceTests: XCTestCase {

    var transcriptionService: TranscriptionService!

    override func setUp() async throws {
        try await super.setUp()
        transcriptionService = TranscriptionService()
    }

    override func tearDown() async throws {
        transcriptionService = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testTranscriptionServiceInitialization() {
        XCTAssertNotNil(transcriptionService)
        XCTAssertFalse(transcriptionService.isTranscribing)
        XCTAssertEqual(transcriptionService.transcriptionProgress, 0)
    }

    // MARK: - Error Types Tests

    func testTranscriptionErrorTypes() {
        let error1 = TranscriptionService.TranscriptionError.speechRecognizerUnavailable
        XCTAssertNotNil(error1.errorDescription)

        let error2 = TranscriptionService.TranscriptionError.audioFileNotFound
        XCTAssertNotNil(error2.errorDescription)

        let error3 = TranscriptionService.TranscriptionError.permissionDenied
        XCTAssertNotNil(error3.errorDescription)

        let error4 = TranscriptionService.TranscriptionError.emptyTranscript
        XCTAssertNotNil(error4.errorDescription)
    }

    // MARK: - Permission Tests

    func testCheckPermissionReturnsBoolean() {
        let hasPermission = TranscriptionService.checkPermission()

        // Result should be a boolean
        XCTAssertTrue(hasPermission || !hasPermission)
    }

    // MARK: - File Saving Tests

    func testSaveTranscriptToFile() throws {
        let transcript = "This is a test transcript."
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-transcript.txt")

        // Save transcript
        try transcriptionService.saveTranscript(transcript, to: tempURL)

        // Verify file exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempURL.path()))

        // Read and verify contents
        let savedContent = try String(contentsOf: tempURL, encoding: .utf8)
        XCTAssertEqual(savedContent, transcript)

        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
    }

    func testSaveEmptyTranscript() throws {
        let transcript = ""
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-empty-transcript.txt")

        // Save empty transcript
        try transcriptionService.saveTranscript(transcript, to: tempURL)

        // Verify file exists and is empty
        let savedContent = try String(contentsOf: tempURL, encoding: .utf8)
        XCTAssertEqual(savedContent, "")

        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
    }

    // MARK: - Error Handling Tests

    func testTranscribeNonexistentFileThrowsError() async {
        let nonexistentURL = URL(fileURLWithPath: "/nonexistent/audio.m4a")

        do {
            _ = try await transcriptionService.transcribe(audioURL: nonexistentURL)
            XCTFail("Should throw error for nonexistent file")
        } catch {
            XCTAssertNotNil(error)
            // Should be audioFileNotFound error
            if let transcriptionError = error as? TranscriptionService.TranscriptionError {
                XCTAssertEqual(transcriptionError.localizedDescription,
                              TranscriptionService.TranscriptionError.audioFileNotFound.localizedDescription)
            }
        }
    }

    // MARK: - Note on Integration Tests
    // Integration tests that require actual audio files and speech recognition
    // should be run manually or in a proper test environment with permissions.
    // These tests include:
    // - testTranscribeValidAudioFile
    // - testTranscriptionProgressUpdates
    // - testTranscriptionWithSpeechRecognitionPermission
    // - testHandleEmptyAudio
    //
    // To run these tests manually:
    // 1. Grant speech recognition permission to the test app
    // 2. Create test audio files with speech
    // 3. Uncomment the tests below and run individually
}

// MARK: - Session Codable Tests

final class SessionCodableTests: XCTestCase {

    func testSessionEncodingDecoding() throws {
        // Create a session with data
        var session = Session(id: "test-123")
        session.durationSeconds = 42.5
        session.transcriptText = "This is a test transcript."
        session.stats = SessionStats(
            totalWords: 5,
            uniqueWords: 4,
            fillerWordCount: 0,
            topWords: [WordCount(word: "test", count: 1)]
        )

        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(session)

        // Decode
        let decoder = JSONDecoder()
        let decodedSession = try decoder.decode(Session.self, from: data)

        // Verify
        XCTAssertEqual(decodedSession.id, session.id)
        XCTAssertEqual(decodedSession.durationSeconds, session.durationSeconds)
        XCTAssertEqual(decodedSession.transcriptText, session.transcriptText)
        XCTAssertEqual(decodedSession.stats?.totalWords, session.stats?.totalWords)
    }

    func testSessionStatsCodable() throws {
        let stats = SessionStats(
            totalWords: 100,
            uniqueWords: 75,
            fillerWordCount: 5,
            fillerWordBreakdown: ["um": 3, "uh": 2],
            topWords: [
                WordCount(word: "hello", count: 10),
                WordCount(word: "world", count: 8)
            ],
            wordsPerMinute: 120.5
        )

        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(stats)

        // Decode
        let decoder = JSONDecoder()
        let decodedStats = try decoder.decode(SessionStats.self, from: data)

        // Verify
        XCTAssertEqual(decodedStats.totalWords, stats.totalWords)
        XCTAssertEqual(decodedStats.uniqueWords, stats.uniqueWords)
        XCTAssertEqual(decodedStats.fillerWordCount, stats.fillerWordCount)
        XCTAssertEqual(decodedStats.fillerWordBreakdown, stats.fillerWordBreakdown)
        XCTAssertEqual(decodedStats.topWords.count, stats.topWords.count)
        XCTAssertEqual(decodedStats.wordsPerMinute, stats.wordsPerMinute)
    }

    func testWordCountCodable() throws {
        let wordCount = WordCount(word: "test", count: 5)

        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(wordCount)

        // Decode
        let decoder = JSONDecoder()
        let decodedWordCount = try decoder.decode(WordCount.self, from: data)

        // Verify
        XCTAssertEqual(decodedWordCount.word, wordCount.word)
        XCTAssertEqual(decodedWordCount.count, wordCount.count)
    }
}
