//
//  CoachingServiceTests.swift
//  SpeechCoachTests
//
//  Created by AI Speech Coach
//

import XCTest
@testable import SpeechCoach

final class CoachingServiceTests: XCTestCase {

    var service: CoachingService!
    var mockKeychain: MockKeychainService!
    var mockSession: URLSession!

    override func setUp() async throws {
        try await super.setUp()

        mockKeychain = MockKeychainService()
        try mockKeychain.save(key: .openAIAPIKey, value: "sk-test-key-123")

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: config)

        service = CoachingService(urlSession: mockSession, keychain: mockKeychain)
    }

    override func tearDown() async throws {
        MockURLProtocol.requestHandler = nil
        service = nil
        mockKeychain = nil
        mockSession = nil
        try await super.tearDown()
    }

    // MARK: - Initialization

    func testInitialization() {
        XCTAssertNotNil(service)
        XCTAssertFalse(service.isAnalyzing)
        XCTAssertEqual(service.analysisProgress, 0)
    }

    // MARK: - Successful Analysis

    func testSuccessfulAnalysis() async throws {
        let coachingJSON = sampleCoachingJSON()

        MockURLProtocol.requestHandler = { request in
            let responseBody = self.wrapInResponsesAPI(coachingJSON)
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200,
                httpVersion: nil, headerFields: nil
            )!
            return (response, responseBody.data(using: .utf8)!)
        }

        let result = try await service.analyze(transcript: "Hello world, this is a test speech.")

        XCTAssertEqual(result.scores.clarity, 8)
        XCTAssertEqual(result.scores.confidence, 7)
        XCTAssertEqual(result.highlights.count, 2)
        XCTAssertEqual(result.actionPlan.count, 2)
        XCTAssertNotNil(result.raw)
    }

    // MARK: - Error Cases

    func testMissingAPIKey() async {
        let emptyKeychain = MockKeychainService()
        let noKeyService = CoachingService(urlSession: mockSession, keychain: emptyKeychain)

        do {
            _ = try await noKeyService.analyze(transcript: "Test transcript")
            XCTFail("Should throw missingAPIKey")
        } catch let error as CoachingService.CoachingError {
            XCTAssertEqual(error, .missingAPIKey)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testEmptyTranscript() async {
        do {
            _ = try await service.analyze(transcript: "")
            XCTFail("Should throw emptyTranscript")
        } catch let error as CoachingService.CoachingError {
            XCTAssertEqual(error, .emptyTranscript)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testWhitespaceOnlyTranscript() async {
        do {
            _ = try await service.analyze(transcript: "   \n\t  ")
            XCTFail("Should throw emptyTranscript")
        } catch let error as CoachingService.CoachingError {
            XCTAssertEqual(error, .emptyTranscript)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testAuthenticationError401() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 401,
                httpVersion: nil, headerFields: nil
            )!
            let json = #"{"error": {"message": "Invalid API key", "type": "auth_error"}}"#
            return (response, json.data(using: .utf8)!)
        }

        do {
            _ = try await service.analyze(transcript: "Test transcript")
            XCTFail("Should throw httpError")
        } catch let error as CoachingService.CoachingError {
            if case .httpError(let code, _) = error {
                XCTAssertEqual(code, 401)
            } else {
                XCTFail("Expected httpError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRateLimited429() async throws {
        var requestCount = 0

        MockURLProtocol.requestHandler = { request in
            requestCount += 1
            if requestCount == 1 {
                let response = HTTPURLResponse(
                    url: request.url!, statusCode: 429,
                    httpVersion: nil, headerFields: ["Retry-After": "1"]
                )!
                return (response, #"{"error": {"message": "Rate limited"}}"#.data(using: .utf8)!)
            } else {
                let responseBody = self.wrapInResponsesAPI(self.sampleCoachingJSON())
                let response = HTTPURLResponse(
                    url: request.url!, statusCode: 200,
                    httpVersion: nil, headerFields: nil
                )!
                return (response, responseBody.data(using: .utf8)!)
            }
        }

        let result = try await service.analyze(transcript: "Test transcript")
        XCTAssertEqual(result.scores.clarity, 8)
        XCTAssertGreaterThanOrEqual(requestCount, 2)
    }

    func testServerError5xxWithRetry() async throws {
        var requestCount = 0

        MockURLProtocol.requestHandler = { request in
            requestCount += 1
            if requestCount == 1 {
                let response = HTTPURLResponse(
                    url: request.url!, statusCode: 500,
                    httpVersion: nil, headerFields: nil
                )!
                return (response, #"{"error": {"message": "Internal server error"}}"#.data(using: .utf8)!)
            } else {
                let responseBody = self.wrapInResponsesAPI(self.sampleCoachingJSON())
                let response = HTTPURLResponse(
                    url: request.url!, statusCode: 200,
                    httpVersion: nil, headerFields: nil
                )!
                return (response, responseBody.data(using: .utf8)!)
            }
        }

        let result = try await service.analyze(transcript: "Test transcript")
        XCTAssertEqual(result.scores.clarity, 8)
        XCTAssertEqual(requestCount, 2)
    }

    func testMalformedJSON() async {
        MockURLProtocol.requestHandler = { request in
            let responseBody = self.wrapInResponsesAPI("This is not valid JSON at all")
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200,
                httpVersion: nil, headerFields: nil
            )!
            return (response, responseBody.data(using: .utf8)!)
        }

        do {
            _ = try await service.analyze(transcript: "Test transcript")
            XCTFail("Should throw malformedJSON")
        } catch let error as CoachingService.CoachingError {
            if case .malformedJSON(_) = error {
                // Expected
            } else {
                XCTFail("Expected malformedJSON, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Request Format

    func testRequestFormatAndHeaders() async throws {
        var capturedRequest: URLRequest?
        var capturedBodyData: Data?

        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            // httpBody may be nil in URLProtocol; read from stream if needed
            if let body = request.httpBody {
                capturedBodyData = body
            } else if let stream = request.httpBodyStream {
                stream.open()
                let bufferSize = 65536
                var data = Data()
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
                defer { buffer.deallocate() }
                while stream.hasBytesAvailable {
                    let bytesRead = stream.read(buffer, maxLength: bufferSize)
                    if bytesRead > 0 {
                        data.append(buffer, count: bytesRead)
                    } else { break }
                }
                stream.close()
                capturedBodyData = data
            }

            let responseBody = self.wrapInResponsesAPI(self.sampleCoachingJSON())
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200,
                httpVersion: nil, headerFields: nil
            )!
            return (response, responseBody.data(using: .utf8)!)
        }

        _ = try await service.analyze(transcript: "Test transcript")

        XCTAssertNotNil(capturedRequest)
        XCTAssertEqual(capturedRequest?.httpMethod, "POST")
        XCTAssertEqual(capturedRequest?.url?.absoluteString, "https://api.openai.com/v1/responses")
        XCTAssertTrue(capturedRequest?.value(forHTTPHeaderField: "Authorization")?.hasPrefix("Bearer ") ?? false)
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Content-Type"), "application/json")

        // Verify body contains model and input
        if let body = capturedBodyData,
           let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] {
            XCTAssertEqual(json["model"] as? String, "gpt-4.1")
            XCTAssertNotNil(json["instructions"] as? String)
            XCTAssertNotNil(json["input"] as? String)
        } else {
            XCTFail("Could not parse request body")
        }
    }

    // MARK: - Prompt Construction

    func testSupportiveStylePrompt() {
        let prompt = service.buildSystemPrompt(style: .supportive)
        XCTAssertTrue(prompt.contains("supportive"))
        XCTAssertTrue(prompt.contains("encouraging"))
    }

    func testDirectStylePrompt() {
        let prompt = service.buildSystemPrompt(style: .direct)
        XCTAssertTrue(prompt.contains("direct"))
    }

    func testDetailedStylePrompt() {
        let prompt = service.buildSystemPrompt(style: .detailed)
        XCTAssertTrue(prompt.contains("thorough"))
    }

    func testUserPromptWithContext() {
        let prompt = service.buildUserPrompt(
            transcript: "Hello world",
            speechGoal: "Persuade the audience",
            targetAudience: "Engineering team",
            durationSeconds: 120
        )

        XCTAssertTrue(prompt.contains("Hello world"))
        XCTAssertTrue(prompt.contains("Persuade the audience"))
        XCTAssertTrue(prompt.contains("Engineering team"))
        XCTAssertTrue(prompt.contains("120"))
    }

    func testUserPromptWithoutContext() {
        let prompt = service.buildUserPrompt(
            transcript: "Hello world",
            speechGoal: nil,
            targetAudience: nil,
            durationSeconds: nil
        )

        XCTAssertTrue(prompt.contains("Hello world"))
        XCTAssertFalse(prompt.contains("Context:"))
    }

    func testUserPromptIgnoresEmptyGoal() {
        let prompt = service.buildUserPrompt(
            transcript: "Hello world",
            speechGoal: "",
            targetAudience: "",
            durationSeconds: nil
        )

        XCTAssertFalse(prompt.contains("Context:"))
    }

    // MARK: - Model & Style Enums

    func testCoachingModelDisplayNames() {
        for model in CoachingService.CoachingModel.allCases {
            XCTAssertFalse(model.displayName.isEmpty)
        }
    }

    func testCoachingStyleDisplayNames() {
        for style in CoachingService.CoachingStyle.allCases {
            XCTAssertFalse(style.displayName.isEmpty)
        }
    }

    func testCoachingModelCodable() throws {
        for model in CoachingService.CoachingModel.allCases {
            let data = try JSONEncoder().encode(model)
            let decoded = try JSONDecoder().decode(CoachingService.CoachingModel.self, from: data)
            XCTAssertEqual(model, decoded)
        }
    }

    func testCoachingStyleCodable() throws {
        for style in CoachingService.CoachingStyle.allCases {
            let data = try JSONEncoder().encode(style)
            let decoded = try JSONDecoder().decode(CoachingService.CoachingStyle.self, from: data)
            XCTAssertEqual(style, decoded)
        }
    }

    // MARK: - Error Descriptions

    func testErrorDescriptions() {
        let errors: [CoachingService.CoachingError] = [
            .missingAPIKey,
            .emptyTranscript,
            .httpError(statusCode: 500, message: "Server error"),
            .rateLimited(retryAfter: 10),
            .rateLimited(retryAfter: nil),
            .malformedJSON("bad json"),
            .networkError("Connection lost"),
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Error \(error) should have a description")
        }
    }

    // MARK: - JSON with Code Fences

    func testHandlesMarkdownCodeFences() async throws {
        let fencedJSON = "```json\n\(sampleCoachingJSON())\n```"

        MockURLProtocol.requestHandler = { request in
            let responseBody = self.wrapInResponsesAPI(fencedJSON)
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200,
                httpVersion: nil, headerFields: nil
            )!
            return (response, responseBody.data(using: .utf8)!)
        }

        let result = try await service.analyze(transcript: "Test speech about coding")
        XCTAssertEqual(result.scores.clarity, 8)
    }

    // MARK: - Helpers

    private func sampleCoachingJSON() -> String {
        return """
        {
          "scores": {"clarity": 8, "confidence": 7, "conciseness": 6, "structure": 9, "persuasion": 5},
          "metrics": {"durationSeconds": 60, "estimatedWPM": 140, "fillerWords": {"um": 2}, "repeatPhrases": []},
          "highlights": [
            {"type": "strength", "text": "Clear opening"},
            {"type": "improvement", "text": "Add stronger conclusion"}
          ],
          "actionPlan": ["Practice pausing", "Add summary at end"],
          "rewrite": {"version": "improved", "text": "Better version..."}
        }
        """
    }

    private func wrapInResponsesAPI(_ text: String) -> String {
        // Escape the text for JSON string embedding
        let escaped = text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\t", with: "\\t")

        return """
        {
          "output": [
            {
              "type": "message",
              "content": [
                {
                  "type": "output_text",
                  "text": "\(escaped)"
                }
              ]
            }
          ]
        }
        """
    }
}
