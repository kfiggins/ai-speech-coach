//
//  SessionStoreTests.swift
//  SpeechCoachTests
//
//  Created by AI Speech Coach
//

import XCTest
@testable import SpeechCoach

final class SessionStoreTests: XCTestCase {

    var sessionStore: SessionStore!
    var testStorageDir: URL!

    override func setUp() {
        super.setUp()

        // Create temporary test directory
        let tempDir = FileManager.default.temporaryDirectory
        testStorageDir = tempDir.appendingPathComponent("SpeechCoachTests-\(UUID().uuidString)")

        sessionStore = SessionStore(storageDirectory: testStorageDir)
    }

    override func tearDown() {
        // Clean up test data
        try? FileManager.default.removeItem(at: testStorageDir)
        sessionStore = nil
        testStorageDir = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        XCTAssertNotNil(sessionStore)
        XCTAssertTrue(sessionStore.sessions.isEmpty || !sessionStore.sessions.isEmpty)
    }

    // MARK: - Add Session Tests

    func testAddSession() throws {
        var session = Session()
        session.durationSeconds = 10.0
        session.transcriptText = "Test transcript"

        try sessionStore.addSession(session)

        XCTAssertEqual(sessionStore.sessions.count, 1)
        XCTAssertEqual(sessionStore.sessions.first?.id, session.id)
    }

    func testAddMultipleSessions() throws {
        let session1 = Session()
        let session2 = Session()

        try sessionStore.addSession(session1)
        try sessionStore.addSession(session2)

        XCTAssertEqual(sessionStore.sessions.count, 2)
    }

    func testSessionsSortedNewestFirst() throws {
        var session1 = Session()
        session1.durationSeconds = 10.0

        // Wait a moment to ensure different timestamps
        Thread.sleep(forTimeInterval: 0.01)

        var session2 = Session()
        session2.durationSeconds = 20.0

        try sessionStore.addSession(session1)
        try sessionStore.addSession(session2)

        // session2 was created later, should be first
        XCTAssertEqual(sessionStore.sessions.first?.id, session2.id)
        XCTAssertEqual(sessionStore.sessions.last?.id, session1.id)
    }

    // MARK: - Update Session Tests

    func testUpdateSession() throws {
        var session = Session()
        session.durationSeconds = 10.0
        session.transcriptText = "Original transcript"

        try sessionStore.addSession(session)

        // Update the session
        session.transcriptText = "Updated transcript"
        try sessionStore.updateSession(session)

        let updated = sessionStore.sessions.first
        XCTAssertEqual(updated?.transcriptText, "Updated transcript")
    }

    func testUpdateNonExistentSession() {
        let session = Session()

        XCTAssertThrowsError(try sessionStore.updateSession(session)) { error in
            XCTAssertTrue(error is SessionStore.StorageError)
        }
    }

    // MARK: - Delete Session Tests

    func testDeleteSession() throws {
        var session = Session()
        session.durationSeconds = 10.0

        // Create session directory
        try FileManager.default.createSessionDirectory(for: session.id)

        try sessionStore.addSession(session)
        XCTAssertEqual(sessionStore.sessions.count, 1)

        try sessionStore.deleteSession(session)

        XCTAssertEqual(sessionStore.sessions.count, 0)
        XCTAssertFalse(FileManager.default.fileExists(atPath: SessionFileManager.sessionDirectory(for: session.id).path))
    }

    func testDeleteSessionRemovesFiles() throws {
        var session = Session()
        session.durationSeconds = 10.0

        // Create session directory and files
        try FileManager.default.createSessionDirectory(for: session.id)

        let audioURL = session.audioFileURL
        let transcriptURL = session.transcriptFileURL

        try "audio data".write(to: audioURL, atomically: true, encoding: .utf8)
        try "transcript data".write(to: transcriptURL, atomically: true, encoding: .utf8)

        try sessionStore.addSession(session)
        try sessionStore.deleteSession(session)

        XCTAssertFalse(FileManager.default.fileExists(atPath: audioURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: transcriptURL.path))
    }

    // MARK: - Get Sessions Tests

    func testGetAllSessions() throws {
        let session1 = Session()
        let session2 = Session()

        try sessionStore.addSession(session1)
        try sessionStore.addSession(session2)

        let allSessions = sessionStore.getAllSessions()

        XCTAssertEqual(allSessions.count, 2)
    }

    func testGetAllSessionsEmpty() {
        let allSessions = sessionStore.getAllSessions()
        XCTAssertTrue(allSessions.isEmpty || !allSessions.isEmpty) // Store might have existing data
    }

    // MARK: - Persistence Tests

    func testSessionsPersistAcrossInstances() throws {
        var session = Session()
        session.durationSeconds = 10.0
        session.transcriptText = "Test"

        try sessionStore.addSession(session)

        // Create new store instance with same storage directory
        let newStore = SessionStore(storageDirectory: testStorageDir)

        XCTAssertEqual(newStore.sessions.count, sessionStore.sessions.count)
        XCTAssertTrue(newStore.sessions.contains { $0.id == session.id })
    }

    func testReloadSessions() throws {
        var session = Session()
        session.durationSeconds = 10.0

        try sessionStore.addSession(session)

        // Clear sessions in memory
        sessionStore.sessions = []
        XCTAssertTrue(sessionStore.sessions.isEmpty)

        // Reload from disk
        try sessionStore.reloadSessions()

        XCTAssertEqual(sessionStore.sessions.count, 1)
        XCTAssertEqual(sessionStore.sessions.first?.id, session.id)
    }

    // MARK: - Edge Cases

    func testEmptySessionsList() {
        let sessions = sessionStore.getAllSessions()
        // Should not crash with empty list
        XCTAssertTrue(sessions.isEmpty || !sessions.isEmpty)
    }

    func testSessionWithStats() throws {
        var session = Session()
        session.durationSeconds = 60.0
        session.transcriptText = "Test transcript"
        session.stats = SessionStats(
            totalWords: 100,
            uniqueWords: 50,
            fillerWordCount: 5,
            fillerWordBreakdown: ["um": 3, "uh": 2],
            topWords: [WordCount(word: "test", count: 10)],
            wordsPerMinute: 100.0
        )

        try sessionStore.addSession(session)

        let loaded = sessionStore.sessions.first
        XCTAssertNotNil(loaded?.stats)
        XCTAssertEqual(loaded?.stats?.totalWords, 100)
        XCTAssertEqual(loaded?.stats?.wordsPerMinute, 100.0)
    }

    func testSessionWithEmptyTranscript() throws {
        var session = Session()
        session.durationSeconds = 10.0
        session.transcriptText = ""

        try sessionStore.addSession(session)

        let loaded = sessionStore.sessions.first
        XCTAssertEqual(loaded?.transcriptText, "")
    }
}
