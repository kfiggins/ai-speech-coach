//
//  TranscriptionService.swift
//  SpeechCoach
//
//  Created by AI Speech Coach
//

import Foundation
import Speech
import Combine

/// Service responsible for transcribing audio files using Apple's Speech framework
class TranscriptionService: ObservableObject {

    // MARK: - Properties

    private let speechRecognizer: SFSpeechRecognizer?

    @Published var isTranscribing = false
    @Published var transcriptionProgress: Double = 0

    // MARK: - Errors

    enum TranscriptionError: LocalizedError {
        case speechRecognizerUnavailable
        case audioFileNotFound
        case transcriptionFailed(Error)
        case permissionDenied
        case emptyTranscript

        var errorDescription: String? {
            switch self {
            case .speechRecognizerUnavailable:
                return "Speech recognizer is not available for this language"
            case .audioFileNotFound:
                return "Audio file not found at specified location"
            case .transcriptionFailed(let error):
                return "Transcription failed: \(error.localizedDescription)"
            case .permissionDenied:
                return "Speech recognition permission denied"
            case .emptyTranscript:
                return "No speech detected in the audio"
            }
        }
    }

    // MARK: - Initialization

    init(locale: Locale = Locale(identifier: "en-US")) {
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
    }

    // MARK: - Transcription

    /// Transcribe an audio file at the given URL
    func transcribe(audioURL: URL) async throws -> String {
        // Check speech recognizer is available
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw TranscriptionError.speechRecognizerUnavailable
        }

        // Check file exists
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            throw TranscriptionError.audioFileNotFound
        }

        // Update state
        await MainActor.run {
            self.isTranscribing = true
            self.transcriptionProgress = 0
        }

        // Create recognition request
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false
        request.taskHint = .unspecified

        // Perform transcription
        do {
            let transcript = try await performRecognition(request: request, recognizer: recognizer)

            // Update state
            await MainActor.run {
                self.isTranscribing = false
                self.transcriptionProgress = 1.0
            }

            // Validate transcript is not empty
            guard !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw TranscriptionError.emptyTranscript
            }

            return transcript

        } catch {
            await MainActor.run {
                self.isTranscribing = false
                self.transcriptionProgress = 0
            }

            if let transcriptionError = error as? TranscriptionError {
                throw transcriptionError
            } else {
                throw TranscriptionError.transcriptionFailed(error)
            }
        }
    }

    /// Save transcript to file
    func saveTranscript(_ transcript: String, to url: URL) throws {
        do {
            try transcript.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            throw TranscriptionError.transcriptionFailed(error)
        }
    }

    // MARK: - Private Methods

    private func performRecognition(request: SFSpeechURLRecognitionRequest, recognizer: SFSpeechRecognizer) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false

            let task = recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    if !hasResumed {
                        hasResumed = true
                        continuation.resume(throwing: error)
                    }
                    return
                }

                guard let result = result else {
                    return
                }

                // Update progress on main actor
                Task { @MainActor in
                    if result.isFinal {
                        self.transcriptionProgress = 1.0
                    } else {
                        // Estimate progress (not exact, but gives user feedback)
                        self.transcriptionProgress = 0.5
                    }
                }

                // If final result, return the transcript
                if result.isFinal {
                    if !hasResumed {
                        hasResumed = true
                        let transcript = result.bestTranscription.formattedString
                        continuation.resume(returning: transcript)
                    }
                }
            }

            // Store task to keep it alive
            // The task will be automatically deallocated when complete
            _ = task
        }
    }

    // MARK: - Permission Check

    /// Check if speech recognition permission is granted
    static func checkPermission() -> Bool {
        return SFSpeechRecognizer.authorizationStatus() == .authorized
    }

    /// Request speech recognition permission
    static func requestPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
}
