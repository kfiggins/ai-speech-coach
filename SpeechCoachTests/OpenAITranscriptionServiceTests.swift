//
//  OpenAITranscriptionServiceTests.swift
//  SpeechCoachTests
//
//  Created by AI Speech Coach
//

import XCTest
@testable import SpeechCoach

// MARK: - Mock URL Protocol

class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - Mock Keychain Service

class MockKeychainService: KeychainService {
    private var storage: [String: String] = [:]

    override func save(key: KeychainKey, value: String) throws {
        storage[key.rawValue] = value
    }

    override func retrieve(key: KeychainKey) -> String? {
        storage[key.rawValue]
    }

    override func delete(key: KeychainKey) throws {
        storage.removeValue(forKey: key.rawValue)
    }
}

// MARK: - OpenAI Transcription Service Tests

final class OpenAITranscriptionServiceTests: XCTestCase {

    var service: OpenAITranscriptionService!
    var mockKeychain: MockKeychainService!
    var mockSession: URLSession!

    override func setUp() async throws {
        try await super.setUp()

        mockKeychain = MockKeychainService()
        try mockKeychain.save(key: .openAIAPIKey, value: "sk-test-key-123")

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: config)

        service = OpenAITranscriptionService(urlSession: mockSession, keychain: mockKeychain)
    }

    override func tearDown() async throws {
        MockURLProtocol.requestHandler = nil
        service = nil
        mockKeychain = nil
        mockSession = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        XCTAssertNotNil(service)
        XCTAssertFalse(service.isTranscribing)
        XCTAssertEqual(service.transcriptionProgress, 0)
    }

    // MARK: - Successful Transcription

    func testSuccessfulTranscription() async throws {
        let tempAudioURL = createTempFile(named: "test-audio.m4a", size: 1024)
        defer { try? FileManager.default.removeItem(at: tempAudioURL) }

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200,
                httpVersion: nil, headerFields: nil
            )!
            let json = #"{"text": "Hello world this is a test"}"#
            return (response, json.data(using: .utf8)!)
        }

        let result = try await service.transcribe(audioURL: tempAudioURL)
        XCTAssertEqual(result, "Hello world this is a test")
    }

    // MARK: - Error Cases

    func testMissingAPIKey() async {
        let emptyKeychain = MockKeychainService()
        let noKeyService = OpenAITranscriptionService(urlSession: mockSession, keychain: emptyKeychain)
        let tempURL = createTempFile(named: "test.m4a", size: 100)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        do {
            _ = try await noKeyService.transcribe(audioURL: tempURL)
            XCTFail("Should throw missingAPIKey")
        } catch let error as OpenAITranscriptionService.TranscriptionError {
            XCTAssertEqual(error, .missingAPIKey)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testAudioFileNotFound() async {
        let nonexistentURL = URL(fileURLWithPath: "/nonexistent/audio.m4a")

        do {
            _ = try await service.transcribe(audioURL: nonexistentURL)
            XCTFail("Should throw audioFileNotFound")
        } catch let error as OpenAITranscriptionService.TranscriptionError {
            XCTAssertEqual(error, .audioFileNotFound)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testFileTooLarge() async {
        let largeFile = createTempFile(named: "large.m4a", size: 26 * 1024 * 1024)
        defer { try? FileManager.default.removeItem(at: largeFile) }

        do {
            _ = try await service.transcribe(audioURL: largeFile)
            XCTFail("Should throw fileTooLarge")
        } catch let error as OpenAITranscriptionService.TranscriptionError {
            if case .fileTooLarge(_) = error {
                // Expected
            } else {
                XCTFail("Expected fileTooLarge, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testAuthenticationError401() async {
        let tempURL = createTempFile(named: "test.m4a", size: 100)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 401,
                httpVersion: nil, headerFields: nil
            )!
            let json = #"{"error": {"message": "Invalid API key", "type": "auth_error"}}"#
            return (response, json.data(using: .utf8)!)
        }

        do {
            _ = try await service.transcribe(audioURL: tempURL)
            XCTFail("Should throw httpError")
        } catch let error as OpenAITranscriptionService.TranscriptionError {
            if case .httpError(let code, _) = error {
                XCTAssertEqual(code, 401)
            } else {
                XCTFail("Expected httpError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testEmptyTranscriptResponse() async {
        let tempURL = createTempFile(named: "test.m4a", size: 100)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200,
                httpVersion: nil, headerFields: nil
            )!
            let json = #"{"text": ""}"#
            return (response, json.data(using: .utf8)!)
        }

        do {
            _ = try await service.transcribe(audioURL: tempURL)
            XCTFail("Should throw emptyTranscript")
        } catch let error as OpenAITranscriptionService.TranscriptionError {
            XCTAssertEqual(error, .emptyTranscript)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Error Description Tests

    func testErrorDescriptions() {
        let errors: [OpenAITranscriptionService.TranscriptionError] = [
            .missingAPIKey,
            .audioFileNotFound,
            .fileTooLarge(30_000_000),
            .httpError(statusCode: 500, message: "Server error"),
            .rateLimited(retryAfter: 10),
            .rateLimited(retryAfter: nil),
            .decodingFailed,
            .networkError("Connection lost"),
            .emptyTranscript
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Error \(error) should have a description")
        }
    }

    // MARK: - Request Format

    func testMultipartRequestIncludesModelAndAuth() async throws {
        let tempURL = createTempFile(named: "test.m4a", size: 100)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200,
                httpVersion: nil, headerFields: nil
            )!
            return (response, #"{"text": "test"}"#.data(using: .utf8)!)
        }

        _ = try await service.transcribe(audioURL: tempURL)

        XCTAssertNotNil(capturedRequest)
        XCTAssertEqual(capturedRequest?.httpMethod, "POST")
        XCTAssertTrue(capturedRequest?.value(forHTTPHeaderField: "Authorization")?.hasPrefix("Bearer ") ?? false)
        XCTAssertTrue(capturedRequest?.value(forHTTPHeaderField: "Content-Type")?.contains("multipart/form-data") ?? false)

        // Verify body contains model name
        if let body = capturedRequest?.httpBody {
            let bodyString = String(data: body, encoding: .utf8)!
            XCTAssertTrue(bodyString.contains("gpt-4o-transcribe"))
            XCTAssertTrue(bodyString.contains("name=\"file\""))
            XCTAssertTrue(bodyString.contains("name=\"model\""))
        }
    }

    // MARK: - Save Transcript

    func testSaveTranscriptToFile() throws {
        let transcript = "This is a test transcript."
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-transcript-\(UUID().uuidString).txt")

        try service.saveTranscript(transcript, to: tempURL)

        XCTAssertTrue(FileManager.default.fileExists(atPath: tempURL.path))
        let saved = try String(contentsOf: tempURL, encoding: .utf8)
        XCTAssertEqual(saved, transcript)

        try? FileManager.default.removeItem(at: tempURL)
    }

    func testSaveEmptyTranscript() throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-empty-\(UUID().uuidString).txt")

        try service.saveTranscript("", to: tempURL)

        let saved = try String(contentsOf: tempURL, encoding: .utf8)
        XCTAssertEqual(saved, "")

        try? FileManager.default.removeItem(at: tempURL)
    }

    // MARK: - Model Selection

    func testDefaultModelIsGpt4oTranscribe() {
        XCTAssertEqual(service.model, .gpt4oTranscribe)
    }

    func testModelDisplayNames() {
        XCTAssertFalse(OpenAITranscriptionService.TranscriptionModel.gpt4oTranscribe.displayName.isEmpty)
        XCTAssertFalse(OpenAITranscriptionService.TranscriptionModel.gpt4oMiniTranscribe.displayName.isEmpty)
    }

    // MARK: - Helpers

    private func createTempFile(named: String, size: Int) -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString)-\(named)")
        let data = Data(repeating: 0, count: size)
        FileManager.default.createFile(atPath: url.path, contents: data)
        return url
    }
}

// MARK: - Session Codable Tests

final class SessionCodableTests: XCTestCase {

    func testSessionEncodingDecoding() throws {
        var session = Session(id: "test-123")
        session.durationSeconds = 42.5
        session.transcriptText = "This is a test transcript."
        session.stats = SessionStats(
            totalWords: 5,
            uniqueWords: 4,
            fillerWordCount: 0,
            topWords: [WordCount(word: "test", count: 1)]
        )

        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(Session.self, from: data)

        XCTAssertEqual(decoded.id, session.id)
        XCTAssertEqual(decoded.durationSeconds, session.durationSeconds)
        XCTAssertEqual(decoded.transcriptText, session.transcriptText)
        XCTAssertEqual(decoded.stats?.totalWords, session.stats?.totalWords)
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

        let data = try JSONEncoder().encode(stats)
        let decoded = try JSONDecoder().decode(SessionStats.self, from: data)

        XCTAssertEqual(decoded.totalWords, stats.totalWords)
        XCTAssertEqual(decoded.uniqueWords, stats.uniqueWords)
        XCTAssertEqual(decoded.fillerWordCount, stats.fillerWordCount)
        XCTAssertEqual(decoded.fillerWordBreakdown, stats.fillerWordBreakdown)
        XCTAssertEqual(decoded.topWords.count, stats.topWords.count)
        XCTAssertEqual(decoded.wordsPerMinute, stats.wordsPerMinute)
    }

    func testWordCountCodable() throws {
        let wordCount = WordCount(word: "test", count: 5)

        let data = try JSONEncoder().encode(wordCount)
        let decoded = try JSONDecoder().decode(WordCount.self, from: data)

        XCTAssertEqual(decoded.word, wordCount.word)
        XCTAssertEqual(decoded.count, wordCount.count)
    }
}
