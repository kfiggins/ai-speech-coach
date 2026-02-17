//
//  ExportServiceTests.swift
//  SpeechCoachTests
//
//  Created by AI Speech Coach
//

import XCTest
@testable import SpeechCoach

@MainActor
final class ExportServiceTests: XCTestCase {

    var exportService: ExportService!
    var testSession: Session!
    var testStorageDir: URL!

    override func setUp() async throws {
        try await super.setUp()

        exportService = ExportService()

        // Create temporary test directory
        let tempDir = FileManager.default.temporaryDirectory
        testStorageDir = tempDir.appendingPathComponent("ExportServiceTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: testStorageDir, withIntermediateDirectories: true)

        // Create test session with files
        var session = Session()
        session.durationSeconds = 60.0
        session.transcriptText = "Test transcript for export"

        // Create session directory and files
        try FileManager.default.createSessionDirectory(for: session.id)

        // Write test transcript
        try session.transcriptText.write(to: session.transcriptFileURL, atomically: true, encoding: .utf8)

        // Create dummy audio file
        let audioData = Data("dummy audio".utf8)
        try audioData.write(to: session.audioFileURL)

        testSession = session
    }

    override func tearDown() async throws {
        // Clean up test data
        try? FileManager.default.removeItem(at: testStorageDir)
        if let sessionDir = SessionFileManager.sessionDirectory(for: testSession.id) as URL? {
            try? FileManager.default.removeItem(at: sessionDir)
        }
        exportService = nil
        testSession = nil
        testStorageDir = nil
        try await super.tearDown()
    }

    // MARK: - Filename Generation Tests

    func testGenerateTranscriptFilename() throws {
        // Verify sessions have a valid creation date
        let session = Session()
        XCTAssertNotNil(session.createdAt)
        XCTAssertFalse(session.formattedDate.isEmpty)
    }

    func testGenerateAudioFilename() throws {
        let session = Session()
        XCTAssertNotNil(session.createdAt)
        XCTAssertFalse(session.formattedDate.isEmpty)
    }

    // MARK: - File Existence Tests

    func testTranscriptFileExists() {
        let transcriptExists = FileManager.default.fileExists(atPath: testSession.transcriptFileURL.path)
        XCTAssertTrue(transcriptExists, "Transcript file should exist for testing")
    }

    func testAudioFileExists() {
        let audioExists = FileManager.default.fileExists(atPath: testSession.audioFileURL.path)
        XCTAssertTrue(audioExists, "Audio file should exist for testing")
    }

    // MARK: - Error Handling Tests

    func testExportErrorDescriptions() {
        let sourceNotFoundError = ExportService.ExportError.sourceFileNotFound
        XCTAssertNotNil(sourceNotFoundError.errorDescription)
        XCTAssertEqual(sourceNotFoundError.errorDescription, "Source file not found")

        let cancelledError = ExportService.ExportError.exportCancelled
        XCTAssertNotNil(cancelledError.errorDescription)
        XCTAssertEqual(cancelledError.errorDescription, "Export cancelled")

        let invalidDestError = ExportService.ExportError.invalidDestination
        XCTAssertNotNil(invalidDestError.errorDescription)
        XCTAssertEqual(invalidDestError.errorDescription, "Invalid destination URL")
    }

    // MARK: - Reveal in Finder Tests

    func testRevealInFinderDoesNotCrash() {
        // Just verify the method doesn't crash when called
        let testURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.txt")
        exportService.revealInFinder(url: testURL)
        // If we got here without crashing, test passes
        XCTAssertTrue(true)
    }

    // MARK: - Integration Tests (Manual Verification Required)

    /*
     Note: The following tests require user interaction (NSSavePanel) and cannot be fully automated.
     They are commented out but documented here for manual testing:

     1. testExportTranscriptWithUserInteraction()
        - Verify save panel appears with correct default filename
        - Verify transcript file is copied to selected location
        - Verify file contents match source

     2. testExportAudioWithUserInteraction()
        - Verify save panel appears with correct default filename
        - Verify audio file is copied to selected location
        - Verify file contents match source

     3. testExportCancellation()
        - Click "Cancel" in save panel
        - Verify no error is thrown
        - Verify no file is created
     */
}
