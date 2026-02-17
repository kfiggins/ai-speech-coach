//
//  OpenAITranscriptionService.swift
//  SpeechCoach
//
//  Created by AI Speech Coach
//

import Foundation
import Combine

/// Service for transcribing audio using OpenAI's Speech-to-Text API
class OpenAITranscriptionService: ObservableObject {

    // MARK: - Types

    enum TranscriptionModel: String, CaseIterable, Codable {
        case gpt4oTranscribe = "gpt-4o-transcribe"
        case gpt4oMiniTranscribe = "gpt-4o-mini-transcribe"

        var displayName: String {
            switch self {
            case .gpt4oTranscribe: return "GPT-4o Transcribe (Best Quality)"
            case .gpt4oMiniTranscribe: return "GPT-4o Mini Transcribe (Faster)"
            }
        }
    }

    enum TranscriptionError: LocalizedError, Equatable {
        case missingAPIKey
        case audioFileNotFound
        case fileTooLarge(Int64)
        case httpError(statusCode: Int, message: String)
        case rateLimited(retryAfter: TimeInterval?)
        case decodingFailed
        case networkError(String)
        case emptyTranscript

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "OpenAI API key not configured. Please set your API key in Settings."
            case .audioFileNotFound:
                return "Audio file not found at the specified location."
            case .fileTooLarge(let size):
                let mb = Double(size) / (1024 * 1024)
                return String(format: "Audio file is too large (%.1f MB). Maximum is 25 MB.", mb)
            case .httpError(let code, let message):
                return "API error (\(code)): \(message)"
            case .rateLimited(let retryAfter):
                if let seconds = retryAfter {
                    return String(format: "Rate limited. Please try again in %.0f seconds.", seconds)
                }
                return "Rate limited. Please try again shortly."
            case .decodingFailed:
                return "Failed to parse the transcription response."
            case .networkError(let message):
                return "Network error: \(message)"
            case .emptyTranscript:
                return "No speech detected in the audio."
            }
        }
    }

    // MARK: - Published Properties

    @Published var isTranscribing = false
    @Published var transcriptionProgress: Double = 0

    // MARK: - Configuration

    var model: TranscriptionModel = .gpt4oTranscribe

    // MARK: - Dependencies

    private let urlSession: URLSession
    private let keychain: KeychainService

    // MARK: - Constants

    static let maxFileSize: Int64 = 25 * 1024 * 1024 // 25 MB
    private static let baseURL = "https://api.openai.com/v1/audio/transcriptions"

    // MARK: - Response Types

    private struct TranscriptionResponse: Codable {
        let text: String
    }

    private struct ErrorResponse: Codable {
        let error: ErrorDetail

        struct ErrorDetail: Codable {
            let message: String
            let type: String?
        }
    }

    // MARK: - Initialization

    init(urlSession: URLSession = .shared, keychain: KeychainService = KeychainService()) {
        self.urlSession = urlSession
        self.keychain = keychain
    }

    // MARK: - Transcription

    /// Transcribe an audio file using OpenAI's API
    func transcribe(audioURL: URL) async throws -> String {
        // Validate file exists
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            throw TranscriptionError.audioFileNotFound
        }

        // Check file size
        let attributes = try FileManager.default.attributesOfItem(atPath: audioURL.path)
        let fileSize = (attributes[.size] as? Int64) ?? 0
        guard fileSize <= Self.maxFileSize else {
            throw TranscriptionError.fileTooLarge(fileSize)
        }

        // Get API key
        guard let apiKey = keychain.retrieve(key: .openAIAPIKey), !apiKey.isEmpty else {
            throw TranscriptionError.missingAPIKey
        }

        // Build request
        let request = try buildMultipartRequest(audioURL: audioURL, apiKey: apiKey)

        // Update state
        await MainActor.run {
            self.isTranscribing = true
            self.transcriptionProgress = 0.1
        }

        do {
            // Perform request with retry
            let response = try await performRequestWithRetry(request, maxRetries: 1)

            // Validate non-empty
            let trimmed = response.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                await MainActor.run {
                    self.isTranscribing = false
                    self.transcriptionProgress = 0
                }
                throw TranscriptionError.emptyTranscript
            }

            await MainActor.run {
                self.isTranscribing = false
                self.transcriptionProgress = 1.0
            }

            return trimmed

        } catch {
            await MainActor.run {
                self.isTranscribing = false
                self.transcriptionProgress = 0
            }
            throw error
        }
    }

    /// Save transcript text to a file
    func saveTranscript(_ transcript: String, to url: URL) throws {
        try transcript.write(to: url, atomically: true, encoding: .utf8)
    }

    // MARK: - Private Methods

    private func buildMultipartRequest(audioURL: URL, apiKey: String) throws -> URLRequest {
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: URL(string: Self.baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add model field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(model.rawValue)\r\n".data(using: .utf8)!)

        // Add response_format field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("json\r\n".data(using: .utf8)!)

        // Add audio file
        let audioData = try Data(contentsOf: audioURL)
        let filename = audioURL.lastPathComponent
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)

        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body
        return request
    }

    private func performRequestWithRetry(_ request: URLRequest, maxRetries: Int) async throws -> TranscriptionResponse {
        var lastError: Error?

        for attempt in 0...maxRetries {
            do {
                return try await performRequest(request)
            } catch let error as TranscriptionError {
                lastError = error
                switch error {
                case .rateLimited(let retryAfter):
                    // Wait for the specified duration or default 5 seconds
                    let delay = retryAfter ?? 5.0
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                case .httpError(let statusCode, _) where statusCode >= 500:
                    if attempt < maxRetries {
                        // Exponential backoff: 1s, 2s, ...
                        let delay = Double(attempt + 1)
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                    throw error
                default:
                    // No retry for other errors (4xx except 429)
                    throw error
                }
            } catch {
                lastError = error
                if attempt < maxRetries {
                    let delay = Double(attempt + 1)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
            }
        }

        throw lastError ?? TranscriptionError.networkError("Unknown error")
    }

    private func performRequest(_ request: URLRequest) async throws -> TranscriptionResponse {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await urlSession.data(for: request)
        } catch {
            throw TranscriptionError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranscriptionError.networkError("Invalid response")
        }

        await MainActor.run {
            self.transcriptionProgress = 0.8
        }

        switch httpResponse.statusCode {
        case 200:
            guard let decoded = try? JSONDecoder().decode(TranscriptionResponse.self, from: data) else {
                throw TranscriptionError.decodingFailed
            }
            return decoded

        case 401, 403:
            let message = parseErrorMessage(from: data) ?? "Authentication failed"
            throw TranscriptionError.httpError(statusCode: httpResponse.statusCode, message: message)

        case 429:
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap { TimeInterval($0) }
            throw TranscriptionError.rateLimited(retryAfter: retryAfter)

        default:
            let message = parseErrorMessage(from: data) ?? "Request failed"
            throw TranscriptionError.httpError(statusCode: httpResponse.statusCode, message: message)
        }
    }

    private func parseErrorMessage(from data: Data) -> String? {
        try? JSONDecoder().decode(ErrorResponse.self, from: data).error.message
    }
}
