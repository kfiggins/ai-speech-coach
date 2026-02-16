//
//  RecordingServiceTests.swift
//  SpeechCoachTests
//
//  Created by AI Speech Coach
//

import XCTest
@testable import SpeechCoach

final class RecordingServiceTests: XCTestCase {

    var recordingService: RecordingService!

    override func setUp() async throws {
        try await super.setUp()
        recordingService = RecordingService()
    }

    override func tearDown() async throws {
        recordingService = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testRecordingServiceInitialization() {
        XCTAssertNotNil(recordingService)
        XCTAssertFalse(recordingService.isRecording)
        XCTAssertEqual(recordingService.recordingDuration, 0)
    }

    // MARK: - Error Handling Tests

    func testStopRecordingWithoutStartThrowsError() async {
        do {
            _ = try await recordingService.stopRecording()
            XCTFail("Should throw error when stopping without starting")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Error Types Tests

    func testRecordingErrorTypes() {
        let error1 = RecordingService.RecordingError.failedToCreateDirectory
        XCTAssertNotNil(error1.errorDescription)

        let error2 = RecordingService.RecordingError.failedToInitializeRecorder
        XCTAssertNotNil(error2.errorDescription)

        let error3 = RecordingService.RecordingError.noActiveSession
        XCTAssertNotNil(error3.errorDescription)

        let error4 = RecordingService.RecordingError.audioFileNotFound
        XCTAssertNotNil(error4.errorDescription)

        let error5 = RecordingService.RecordingError.invalidDuration
        XCTAssertNotNil(error5.errorDescription)
    }

    // MARK: - Note on Integration Tests
    // Integration tests that require actual microphone access and recording
    // should be run manually or in a proper test environment with permissions.
    // These tests include:
    // - testStartRecordingCreatesSession
    // - testSessionIDGeneration
    // - testRecordingStateChanges
    // - testRecordingDurationUpdates
    // - testRecordingCreatesValidFile
    // - testSessionDurationIsRecorded
    //
    // To run these tests manually:
    // 1. Grant microphone permission to the test app
    // 2. Uncomment the tests below and run individually
}
