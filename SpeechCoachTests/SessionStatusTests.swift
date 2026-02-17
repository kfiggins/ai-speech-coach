//
//  SessionStatusTests.swift
//  SpeechCoachTests
//
//  Created by AI Speech Coach
//

import XCTest
@testable import SpeechCoach

final class SessionStatusTests: XCTestCase {

    func testSessionStatusDisplayText() {
        XCTAssertEqual(SessionStatus.idle.displayText, "Idle")
        XCTAssertEqual(SessionStatus.recording.displayText, "Recording")
        XCTAssertEqual(SessionStatus.ready.displayText, "Ready")
    }

    func testIsRecording() {
        XCTAssertTrue(SessionStatus.recording.isRecording)
        XCTAssertFalse(SessionStatus.idle.isRecording)
        XCTAssertFalse(SessionStatus.ready.isRecording)
    }

    func testCanStartRecording() {
        XCTAssertTrue(SessionStatus.idle.canStartRecording)
        XCTAssertTrue(SessionStatus.ready.canStartRecording)
        XCTAssertFalse(SessionStatus.recording.canStartRecording)
    }

    func testStatusProgression() {
        // Test typical status flow: idle → recording → ready
        var status = SessionStatus.idle
        XCTAssertTrue(status.canStartRecording)

        status = .recording
        XCTAssertTrue(status.isRecording)
        XCTAssertFalse(status.canStartRecording)

        status = .ready
        XCTAssertFalse(status.isRecording)
        XCTAssertTrue(status.canStartRecording)
    }
}
