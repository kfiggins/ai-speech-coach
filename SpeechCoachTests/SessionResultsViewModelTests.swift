//
//  SessionResultsViewModelTests.swift
//  SpeechCoachTests
//
//  Created by AI Speech Coach
//

import XCTest
@testable import SpeechCoach

@MainActor
final class SessionResultsViewModelTests: XCTestCase {

    var viewModel: SessionResultsViewModel!
    var sessionStore: SessionStore!
    var testStorageDir: URL!
    var testSession: Session!

    override func setUp() async throws {
        try await super.setUp()

        // Create temporary test directory
        let tempDir = FileManager.default.temporaryDirectory
        testStorageDir = tempDir.appendingPathComponent("SessionResultsTests-\(UUID().uuidString)")

        sessionStore = SessionStore(storageDirectory: testStorageDir)

        // Create test session
        var session = Session()
        session.durationSeconds = 120.0
        session.transcriptText = "Test transcript"
        session.stats = SessionStats(
            totalWords: 50,
            uniqueWords: 30,
            fillerWordCount: 5,
            fillerWordBreakdown: ["um": 3, "uh": 2],
            topWords: [WordCount(word: "test", count: 10)],
            wordsPerMinute: 25.0
        )

        try sessionStore.addSession(session)
        testSession = session

        viewModel = SessionResultsViewModel(session: session, sessionStore: sessionStore)
    }

    override func tearDown() async throws {
        // Clean up test data
        try? FileManager.default.removeItem(at: testStorageDir)
        viewModel = nil
        sessionStore = nil
        testStorageDir = nil
        testSession = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel.session.id, testSession.id)
        XCTAssertFalse(viewModel.showingDeleteConfirmation)
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - Delete Tests

    func testConfirmDelete() {
        viewModel.confirmDelete()
        XCTAssertTrue(viewModel.showingDeleteConfirmation)
    }

    func testDeleteSessionSuccess() throws {
        let sessionId = testSession.id
        XCTAssertEqual(sessionStore.sessions.count, 1)

        viewModel.deleteSession()

        XCTAssertEqual(sessionStore.sessions.count, 0)
        XCTAssertFalse(sessionStore.sessions.contains { $0.id == sessionId })
        XCTAssertNil(viewModel.errorMessage)
    }

    func testDeleteSessionCallsCallback() {
        var callbackCalled = false
        viewModel.onDeleted = {
            callbackCalled = true
        }

        viewModel.deleteSession()

        XCTAssertTrue(callbackCalled)
    }

    func testDeleteNonExistentSessionFails() {
        // Delete the session first
        try? sessionStore.deleteSession(testSession)

        // Try to delete again
        viewModel.deleteSession()

        // Should have error message
        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - Helper Tests

    func testHasStats() {
        XCTAssertTrue(viewModel.hasStats)

        var sessionWithoutStats = Session()
        sessionWithoutStats.transcriptText = "Test"
        let vmNoStats = SessionResultsViewModel(session: sessionWithoutStats, sessionStore: sessionStore)

        XCTAssertFalse(vmNoStats.hasStats)
    }

    func testHasTranscript() {
        XCTAssertTrue(viewModel.hasTranscript)

        let sessionWithoutTranscript = Session()
        let vmNoTranscript = SessionResultsViewModel(session: sessionWithoutTranscript, sessionStore: sessionStore)

        XCTAssertFalse(vmNoTranscript.hasTranscript)
    }

    func testFormattedDuration() {
        XCTAssertEqual(viewModel.formattedDuration, "2:00")

        var shortSession = Session()
        shortSession.durationSeconds = 45.0
        let vmShort = SessionResultsViewModel(session: shortSession, sessionStore: sessionStore)

        XCTAssertEqual(vmShort.formattedDuration, "0:45")

        var longSession = Session()
        longSession.durationSeconds = 3665.0 // 1 hour, 1 minute, 5 seconds
        let vmLong = SessionResultsViewModel(session: longSession, sessionStore: sessionStore)

        XCTAssertEqual(vmLong.formattedDuration, "61:05")
    }
}
