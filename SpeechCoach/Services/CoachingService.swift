//
//  CoachingService.swift
//  SpeechCoach
//
//  Created by AI Speech Coach
//

import Foundation
import Combine

/// Service for analyzing speech transcripts using OpenAI's Responses API
class CoachingService: ObservableObject {

    // MARK: - Types

    enum CoachingModel: String, CaseIterable, Codable {
        case gpt4_1 = "gpt-4.1"
        case gpt4o = "gpt-4o"
        case gpt4_1_mini = "gpt-4.1-mini"

        var displayName: String {
            switch self {
            case .gpt4_1: return "GPT-4.1 (Best Quality)"
            case .gpt4o: return "GPT-4o"
            case .gpt4_1_mini: return "GPT-4.1 Mini (Faster)"
            }
        }
    }

    enum CoachingStyle: String, CaseIterable, Codable {
        case supportive
        case direct
        case detailed

        var displayName: String {
            switch self {
            case .supportive: return "Supportive"
            case .direct: return "Direct"
            case .detailed: return "Detailed"
            }
        }

        var systemPromptFragment: String {
            switch self {
            case .supportive:
                return "You are a supportive and encouraging speech coach. Lead with strengths, then gently suggest improvements."
            case .direct:
                return "You are a direct and no-nonsense speech coach. Be concise and focus on the most impactful improvements."
            case .detailed:
                return "You are a thorough and analytical speech coach. Provide detailed analysis with specific examples from the transcript."
            }
        }
    }

    enum CoachingError: LocalizedError, Equatable {
        case missingAPIKey
        case emptyTranscript
        case httpError(statusCode: Int, message: String)
        case rateLimited(retryAfter: TimeInterval?)
        case malformedJSON(String)
        case networkError(String)

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "OpenAI API key not configured. Please set your API key in Settings."
            case .emptyTranscript:
                return "No transcript to analyze. Please transcribe the session first."
            case .httpError(let code, let message):
                return "API error (\(code)): \(message)"
            case .rateLimited(let retryAfter):
                if let seconds = retryAfter {
                    return String(format: "Rate limited. Please try again in %.0f seconds.", seconds)
                }
                return "Rate limited. Please try again shortly."
            case .malformedJSON(let detail):
                return "Failed to parse coaching response: \(detail)"
            case .networkError(let message):
                return "Network error: \(message)"
            }
        }
    }

    // MARK: - Published Properties

    @Published var isAnalyzing = false
    @Published var analysisProgress: Double = 0

    // MARK: - Dependencies

    private let urlSession: URLSession
    private let keychain: KeychainService

    // MARK: - Constants

    private static let baseURL = "https://api.openai.com/v1/responses"

    // MARK: - Response Types

    private struct ResponsesAPIResponse: Codable {
        let output: [OutputItem]

        struct OutputItem: Codable {
            let type: String
            let content: [ContentItem]?
        }

        struct ContentItem: Codable {
            let type: String
            let text: String?
        }
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

    // MARK: - Analysis

    /// Analyze a transcript and return coaching results
    func analyze(
        transcript: String,
        model: CoachingModel = .gpt4_1,
        style: CoachingStyle = .supportive,
        speechGoal: String? = nil,
        targetAudience: String? = nil,
        durationSeconds: Double? = nil
    ) async throws -> CoachingResult {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw CoachingError.emptyTranscript
        }

        guard let apiKey = keychain.retrieve(key: .openAIAPIKey), !apiKey.isEmpty else {
            throw CoachingError.missingAPIKey
        }

        let request = buildRequest(
            transcript: trimmed,
            model: model,
            style: style,
            speechGoal: speechGoal,
            targetAudience: targetAudience,
            durationSeconds: durationSeconds,
            apiKey: apiKey
        )

        await MainActor.run {
            self.isAnalyzing = true
            self.analysisProgress = 0.1
        }

        do {
            let rawText = try await performRequestWithRetry(request, maxRetries: 1)

            await MainActor.run {
                self.analysisProgress = 0.8
            }

            let result = try parseCoachingResult(from: rawText)

            await MainActor.run {
                self.isAnalyzing = false
                self.analysisProgress = 1.0
            }

            return result

        } catch {
            await MainActor.run {
                self.isAnalyzing = false
                self.analysisProgress = 0
            }
            throw error
        }
    }

    // MARK: - Private Methods

    private func buildRequest(
        transcript: String,
        model: CoachingModel,
        style: CoachingStyle,
        speechGoal: String?,
        targetAudience: String?,
        durationSeconds: Double?,
        apiKey: String
    ) -> URLRequest {
        var request = URLRequest(url: URL(string: Self.baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let systemPrompt = buildSystemPrompt(style: style)
        let userPrompt = buildUserPrompt(
            transcript: transcript,
            speechGoal: speechGoal,
            targetAudience: targetAudience,
            durationSeconds: durationSeconds
        )

        let body: [String: Any] = [
            "model": model.rawValue,
            "instructions": systemPrompt,
            "input": userPrompt
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return request
    }

    func buildSystemPrompt(style: CoachingStyle) -> String {
        return """
        \(style.systemPromptFragment)

        Analyze the speech transcript provided and output ONLY valid JSON matching this exact schema (no markdown, no extra text):

        {
          "scores": {
            "clarity": <1-10>,
            "confidence": <1-10>,
            "conciseness": <1-10>,
            "structure": <1-10>,
            "persuasion": <1-10>
          },
          "metrics": {
            "durationSeconds": <number or null>,
            "estimatedWPM": <number or null>,
            "fillerWords": {"word": count} or null,
            "repeatPhrases": ["phrase"] or null
          },
          "highlights": [
            {"type": "strength", "text": "..."},
            {"type": "improvement", "text": "..."}
          ],
          "actionPlan": ["Step 1...", "Step 2...", "Step 3..."],
          "rewrite": {"version": "improved", "text": "..."} or null
        }
        """
    }

    func buildUserPrompt(
        transcript: String,
        speechGoal: String?,
        targetAudience: String?,
        durationSeconds: Double?
    ) -> String {
        var prompt = "Please analyze this speech transcript:\n\n\(transcript)"

        var context: [String] = []
        if let goal = speechGoal, !goal.isEmpty {
            context.append("Speech goal: \(goal)")
        }
        if let audience = targetAudience, !audience.isEmpty {
            context.append("Target audience: \(audience)")
        }
        if let duration = durationSeconds, duration > 0 {
            context.append(String(format: "Duration: %.0f seconds", duration))
        }

        if !context.isEmpty {
            prompt += "\n\nContext:\n" + context.joined(separator: "\n")
        }

        return prompt
    }

    private func performRequestWithRetry(_ request: URLRequest, maxRetries: Int) async throws -> String {
        var lastError: Error?

        for attempt in 0...maxRetries {
            do {
                return try await performRequest(request)
            } catch let error as CoachingError {
                lastError = error
                switch error {
                case .rateLimited(let retryAfter):
                    let delay = retryAfter ?? 5.0
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                case .httpError(let statusCode, _) where statusCode >= 500:
                    if attempt < maxRetries {
                        let delay = Double(attempt + 1)
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                    throw error
                default:
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

        throw lastError ?? CoachingError.networkError("Unknown error")
    }

    private func performRequest(_ request: URLRequest) async throws -> String {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await urlSession.data(for: request)
        } catch {
            throw CoachingError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CoachingError.networkError("Invalid response")
        }

        await MainActor.run {
            self.analysisProgress = 0.5
        }

        switch httpResponse.statusCode {
        case 200:
            return try extractTextFromResponse(data)

        case 401, 403:
            let message = parseErrorMessage(from: data) ?? "Authentication failed"
            throw CoachingError.httpError(statusCode: httpResponse.statusCode, message: message)

        case 429:
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap { TimeInterval($0) }
            throw CoachingError.rateLimited(retryAfter: retryAfter)

        default:
            let message = parseErrorMessage(from: data) ?? "Request failed"
            throw CoachingError.httpError(statusCode: httpResponse.statusCode, message: message)
        }
    }

    private func extractTextFromResponse(_ data: Data) throws -> String {
        guard let decoded = try? JSONDecoder().decode(ResponsesAPIResponse.self, from: data) else {
            throw CoachingError.malformedJSON("Could not decode API response")
        }

        // Find the first message output with text content
        for output in decoded.output {
            if output.type == "message", let contents = output.content {
                for content in contents {
                    if content.type == "output_text", let text = content.text, !text.isEmpty {
                        return text
                    }
                }
            }
        }

        throw CoachingError.malformedJSON("No text content in API response")
    }

    private func parseCoachingResult(from rawText: String) throws -> CoachingResult {
        // Strip any markdown code fences the model might include
        let cleaned = rawText
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleaned.data(using: .utf8) else {
            throw CoachingError.malformedJSON("Invalid text encoding")
        }

        do {
            var result = try JSONDecoder().decode(CoachingResult.self, from: jsonData)
            // Store the raw response for debugging
            result = CoachingResult(
                scores: result.scores,
                metrics: result.metrics,
                highlights: result.highlights,
                actionPlan: result.actionPlan,
                rewrite: result.rewrite,
                raw: rawText
            )
            return result
        } catch let decodingError {
            throw CoachingError.malformedJSON(decodingError.localizedDescription)
        }
    }

    private func parseErrorMessage(from data: Data) -> String? {
        try? JSONDecoder().decode(ErrorResponse.self, from: data).error.message
    }
}
