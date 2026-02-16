//
//  FileManagerSessionsTests.swift
//  SpeechCoachTests
//
//  Created by AI Speech Coach
//

import XCTest
@testable import SpeechCoach

final class FileManagerSessionsTests: XCTestCase {

    let fileManager = FileManager.default
    var testSessionId: String!

    override func setUp() {
        super.setUp()
        testSessionId = UUID().uuidString
    }

    override func tearDown() {
        // Clean up test directory
        try? fileManager.deleteSessionDirectory(for: testSessionId)
        testSessionId = nil
        super.tearDown()
    }

    // MARK: - Directory Creation Tests

    func testCreateSessionDirectory() throws {
        try fileManager.createSessionDirectory(for: testSessionId)

        let sessionDir = SessionFileManager.sessionDirectory(for: testSessionId)
        XCTAssertTrue(fileManager.fileExists(atPath: sessionDir.path))
    }

    func testCreateSessionDirectoryIdempotent() throws {
        // Should not fail if directory already exists
        try fileManager.createSessionDirectory(for: testSessionId)
        try fileManager.createSessionDirectory(for: testSessionId)

        let sessionDir = SessionFileManager.sessionDirectory(for: testSessionId)
        XCTAssertTrue(fileManager.fileExists(atPath: sessionDir.path))
    }

    // MARK: - Directory Deletion Tests

    func testDeleteSessionDirectory() throws {
        try fileManager.createSessionDirectory(for: testSessionId)

        let sessionDir = SessionFileManager.sessionDirectory(for: testSessionId)
        XCTAssertTrue(fileManager.fileExists(atPath: sessionDir.path))

        try fileManager.deleteSessionDirectory(for: testSessionId)

        XCTAssertFalse(fileManager.fileExists(atPath: sessionDir.path))
    }

    func testDeleteSessionDirectoryWithFiles() throws {
        try fileManager.createSessionDirectory(for: testSessionId)

        let audioURL = SessionFileManager.audioFileURL(for: testSessionId)
        let transcriptURL = SessionFileManager.transcriptFileURL(for: testSessionId)

        // Create files
        try "audio".write(to: audioURL, atomically: true, encoding: .utf8)
        try "transcript".write(to: transcriptURL, atomically: true, encoding: .utf8)

        XCTAssertTrue(fileManager.fileExists(atPath: audioURL.path))
        XCTAssertTrue(fileManager.fileExists(atPath: transcriptURL.path))

        // Delete directory
        try fileManager.deleteSessionDirectory(for: testSessionId)

        XCTAssertFalse(fileManager.fileExists(atPath: audioURL.path))
        XCTAssertFalse(fileManager.fileExists(atPath: transcriptURL.path))
    }

    func testDeleteNonExistentDirectory() throws {
        // Should not fail if directory doesn't exist
        try fileManager.deleteSessionDirectory(for: testSessionId)
    }

    // MARK: - File Existence Tests

    func testSessionFilesExist() throws {
        try fileManager.createSessionDirectory(for: testSessionId)

        let audioURL = SessionFileManager.audioFileURL(for: testSessionId)
        let transcriptURL = SessionFileManager.transcriptFileURL(for: testSessionId)

        // Files don't exist yet
        XCTAssertFalse(fileManager.sessionFilesExist(for: testSessionId))

        // Create files
        try "audio".write(to: audioURL, atomically: true, encoding: .utf8)
        try "transcript".write(to: transcriptURL, atomically: true, encoding: .utf8)

        // Now they exist
        XCTAssertTrue(fileManager.sessionFilesExist(for: testSessionId))
    }

    func testAudioFileExists() throws {
        try fileManager.createSessionDirectory(for: testSessionId)

        let audioURL = SessionFileManager.audioFileURL(for: testSessionId)

        XCTAssertFalse(fileManager.audioFileExists(for: testSessionId))

        try "audio".write(to: audioURL, atomically: true, encoding: .utf8)

        XCTAssertTrue(fileManager.audioFileExists(for: testSessionId))
    }

    // MARK: - File Size Tests

    func testAudioFileSize() throws {
        try fileManager.createSessionDirectory(for: testSessionId)

        let audioURL = SessionFileManager.audioFileURL(for: testSessionId)

        // No file yet
        XCTAssertNil(fileManager.audioFileSize(for: testSessionId))

        // Create file with known content
        let content = "test audio content"
        try content.write(to: audioURL, atomically: true, encoding: .utf8)

        let size = fileManager.audioFileSize(for: testSessionId)
        XCTAssertNotNil(size)
        XCTAssertGreaterThan(size!, 0)
    }

    // MARK: - Path Tests

    func testSessionDirectoryPath() {
        let sessionDir = SessionFileManager.sessionDirectory(for: testSessionId)

        XCTAssertTrue(sessionDir.path.contains("SpeechCoach"))
        XCTAssertTrue(sessionDir.path.contains("Sessions"))
        XCTAssertTrue(sessionDir.path.contains(testSessionId))
    }

    func testAudioFileURLPath() {
        let audioURL = SessionFileManager.audioFileURL(for: testSessionId)

        XCTAssertTrue(audioURL.path.contains(testSessionId))
        XCTAssertTrue(audioURL.path.hasSuffix("audio.m4a"))
    }

    func testTranscriptFileURLPath() {
        let transcriptURL = SessionFileManager.transcriptFileURL(for: testSessionId)

        XCTAssertTrue(transcriptURL.path.contains(testSessionId))
        XCTAssertTrue(transcriptURL.path.hasSuffix("transcript.txt"))
    }
}
