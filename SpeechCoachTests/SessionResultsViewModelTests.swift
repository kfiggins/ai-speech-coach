//
//  SessionResultsViewModelTests.swift
//  SpeechCoachTests
//
//  Created by AI Speech Coach
//

import XCTest
import AVFoundation
@testable import SpeechCoach

@MainActor
final class SessionResultsViewModelTests: XCTestCase {

    var viewModel: SessionResultsViewModel!
    var sessionStore: SessionStore!
    var testStorageDir: URL!
    var testSession: Session!
    var mockKeychain: MockKeychainService!
    var mockURLSession: URLSession!

    override func setUp() async throws {
        try await super.setUp()

        // Create temporary test directory
        let tempDir = FileManager.default.temporaryDirectory
        testStorageDir = tempDir.appendingPathComponent("SessionResultsTests-\(UUID().uuidString)")

        sessionStore = SessionStore(storageDirectory: testStorageDir)

        // Set up mock networking
        mockKeychain = MockKeychainService()
        try mockKeychain.save(key: .openAIAPIKey, value: "sk-test-key-123")

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        mockURLSession = URLSession(configuration: config)

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

        viewModel = SessionResultsViewModel(
            session: session,
            sessionStore: sessionStore,
            transcriptionService: OpenAITranscriptionService(urlSession: mockURLSession, keychain: mockKeychain),
            coachingService: CoachingService(urlSession: mockURLSession, keychain: mockKeychain)
        )
    }

    override func tearDown() async throws {
        MockURLProtocol.requestHandler = nil
        try? FileManager.default.removeItem(at: testStorageDir)
        viewModel = nil
        sessionStore = nil
        testStorageDir = nil
        testSession = nil
        mockKeychain = nil
        mockURLSession = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel.session.id, testSession.id)
        XCTAssertFalse(viewModel.showingDeleteConfirmation)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isTranscribing)
        XCTAssertFalse(viewModel.isAnalyzingCoaching)
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

    func testDeleteAlreadyDeletedSessionIsGraceful() {
        // Delete the session first
        try? sessionStore.deleteSession(testSession)

        // Deleting again should not crash or error (graceful no-op)
        viewModel.deleteSession()

        // No error because SessionStore silently handles missing sessions
        XCTAssertNil(viewModel.errorMessage)
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

    // MARK: - Transcription Tests

    func testTranscribeSessionSuccess() async throws {
        // Create a session without transcript but with a real audio file
        var emptySession = Session()
        emptySession.durationSeconds = 5.0

        // Create the session directory and a dummy audio file
        let sessionDir = SessionFileManager.sessionDirectory(for: emptySession.id)
        try FileManager.default.createDirectory(at: sessionDir, withIntermediateDirectories: true)
        let audioData = try createMinimalWAVData()
        try audioData.write(to: emptySession.audioFileURL)

        try sessionStore.addSession(emptySession)

        let vm = SessionResultsViewModel(
            session: emptySession,
            sessionStore: sessionStore,
            transcriptionService: OpenAITranscriptionService(urlSession: mockURLSession, keychain: mockKeychain),
            coachingService: CoachingService(urlSession: mockURLSession, keychain: mockKeychain)
        )

        // Mock transcription response
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200,
                httpVersion: nil, headerFields: nil
            )!
            let json = #"{"text": "Hello world this is a transcription test"}"#
            return (response, json.data(using: .utf8)!)
        }

        await vm.transcribeSession()

        XCTAssertFalse(vm.isTranscribing)
        XCTAssertNil(vm.errorMessage)
        XCTAssertTrue(vm.hasTranscript)
        XCTAssertEqual(vm.session.transcriptText, "Hello world this is a transcription test")
        XCTAssertNotNil(vm.session.stats)

        // Clean up
        try? FileManager.default.removeItem(at: sessionDir)
    }

    func testTranscribeSessionErrorPreservesSession() async throws {
        // Create session with no audio file (will fail at file-not-found)
        var emptySession = Session()
        emptySession.durationSeconds = 5.0
        try sessionStore.addSession(emptySession)

        let vm = SessionResultsViewModel(
            session: emptySession,
            sessionStore: sessionStore,
            transcriptionService: OpenAITranscriptionService(urlSession: mockURLSession, keychain: mockKeychain),
            coachingService: CoachingService(urlSession: mockURLSession, keychain: mockKeychain)
        )

        await vm.transcribeSession()

        XCTAssertFalse(vm.isTranscribing)
        XCTAssertNotNil(vm.errorMessage)
        // Session should still be intact
        XCTAssertFalse(vm.hasTranscript)
    }

    // MARK: - Coaching Tests

    func testAnalyzeCoachingSuccess() async throws {
        // viewModel already has a session with transcript
        let coachingJSON = """
        {
          "scores": {"clarity": 8, "confidence": 7, "conciseness": 6, "structure": 9, "persuasion": 5},
          "metrics": {"durationSeconds": 120, "estimatedWPM": 25, "fillerWords": {"um": 3}, "repeatPhrases": []},
          "highlights": [{"type": "strength", "text": "Good pacing"}],
          "actionPlan": ["Practice more"],
          "rewrite": null
        }
        """

        let escaped = coachingJSON
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")

        let responsesAPIJSON = """
        {"output": [{"type": "message", "content": [{"type": "output_text", "text": "\(escaped)"}]}]}
        """

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200,
                httpVersion: nil, headerFields: nil
            )!
            return (response, responsesAPIJSON.data(using: .utf8)!)
        }

        await viewModel.analyzeCoaching()

        XCTAssertFalse(viewModel.isAnalyzingCoaching)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.session.hasCoaching)
        XCTAssertEqual(viewModel.session.coachingResult?.scores.clarity, 8)
    }

    func testAnalyzeCoachingRequiresTranscript() async {
        let emptySession = Session()
        let vm = SessionResultsViewModel(
            session: emptySession,
            sessionStore: sessionStore,
            transcriptionService: OpenAITranscriptionService(urlSession: mockURLSession, keychain: mockKeychain),
            coachingService: CoachingService(urlSession: mockURLSession, keychain: mockKeychain)
        )

        await vm.analyzeCoaching()

        XCTAssertFalse(vm.isAnalyzingCoaching)
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertFalse(vm.session.hasCoaching)
    }

    // MARK: - Helpers

    private func createMinimalWAVData() throws -> Data {
        let sampleRate: Double = 44100.0
        let duration: Double = 0.5
        let frameCount = Int(sampleRate * duration)

        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        ) else {
            throw NSError(domain: "Test", code: 1)
        }

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else {
            throw NSError(domain: "Test", code: 2)
        }
        buffer.frameLength = AVAudioFrameCount(frameCount)

        // Fill with a sine wave
        if let samples = buffer.floatChannelData?[0] {
            for i in 0..<frameCount {
                samples[i] = 0.5 * Float(sin(2.0 * Double.pi * 440.0 * Double(i) / sampleRate))
            }
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-wav-\(UUID().uuidString).wav")
        let file = try AVAudioFile(forWriting: tempURL, settings: format.settings)
        try file.write(from: buffer)

        let data = try Data(contentsOf: tempURL)
        try? FileManager.default.removeItem(at: tempURL)
        return data
    }
}
