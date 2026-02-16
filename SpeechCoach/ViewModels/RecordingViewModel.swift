//
//  RecordingViewModel.swift
//  SpeechCoach
//
//  Created by AI Speech Coach
//

import Foundation
import SwiftUI

/// ViewModel managing the recording flow and state
@MainActor
class RecordingViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var status: SessionStatus = .idle
    @Published var currentSession: Session?
    @Published var recordingDuration: TimeInterval = 0
    @Published var transcriptionProgress: Double = 0
    @Published var errorMessage: String?
    @Published var showingPermissionAlert = false
    @Published var permissionAlertMessage = ""

    // MARK: - Services

    private let permissionManager: PermissionManager
    private let recordingService: RecordingService
    private let transcriptionService: TranscriptionService

    // MARK: - Initialization

    init(
        permissionManager: PermissionManager = PermissionManager(),
        recordingService: RecordingService = RecordingService(),
        transcriptionService: TranscriptionService = TranscriptionService()
    ) {
        self.permissionManager = permissionManager
        self.recordingService = recordingService
        self.transcriptionService = transcriptionService

        // Observe services
        observeRecordingService()
        observeTranscriptionService()
    }

    // MARK: - Recording Control

    /// Start a new recording session
    func startRecording() {
        Task {
            do {
                // Request microphone permission
                let micStatus = await permissionManager.requestMicrophonePermission()

                guard micStatus.isGranted else {
                    showPermissionDeniedAlert(for: .microphone)
                    return
                }

                // Start recording
                status = .recording
                let session = try await recordingService.startRecording()
                currentSession = session

            } catch {
                handleError(error)
            }
        }
    }

    /// Stop the current recording
    func stopRecording() {
        Task {
            do {
                status = .processing

                // Stop recording and get final session
                var session = try await recordingService.stopRecording()

                // Request speech recognition permission if needed
                let speechStatus = await permissionManager.requestSpeechRecognitionPermission()

                if speechStatus.isGranted {
                    // Transcribe the audio
                    do {
                        let transcript = try await transcriptionService.transcribe(audioURL: session.audioFileURL)
                        session.transcriptText = transcript

                        // Save transcript to file
                        try transcriptionService.saveTranscript(transcript, to: session.transcriptFileURL)

                    } catch {
                        // Transcription failed, but keep the audio
                        print("Transcription failed: \(error.localizedDescription)")
                        session.transcriptText = ""
                        // Show a non-blocking error message
                        errorMessage = "Transcription failed, but audio was saved. \(error.localizedDescription)"
                    }
                } else {
                    // Permission denied, skip transcription
                    session.transcriptText = ""
                    showPermissionDeniedAlert(for: .speechRecognition)
                }

                currentSession = session

                // Move to ready state
                status = .ready

            } catch {
                handleError(error)
            }
        }
    }

    /// Toggle recording state
    func toggleRecording() {
        if status.isRecording {
            stopRecording()
        } else if status.canStartRecording {
            startRecording()
        }
    }

    // MARK: - Permission Handling

    enum PermissionType {
        case microphone
        case speechRecognition

        var alertMessage: String {
            switch self {
            case .microphone:
                return """
                Speech Coach needs microphone access to record your sessions.

                Please allow access in System Settings > Privacy & Security > Microphone.
                """
            case .speechRecognition:
                return """
                Speech Coach needs permission to transcribe your recordings.

                Please allow access in System Settings > Privacy & Security > Speech Recognition.

                You can still record and export audio without transcription.
                """
            }
        }
    }

    private func showPermissionDeniedAlert(for type: PermissionType) {
        permissionAlertMessage = type.alertMessage
        showingPermissionAlert = true
        status = .idle
    }

    // MARK: - Error Handling

    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        status = .idle
        currentSession = nil

        print("Recording error: \(error.localizedDescription)")
    }

    // MARK: - Observation

    private func observeRecordingService() {
        // Observe recording duration updates
        Task {
            for await duration in observeDuration() {
                self.recordingDuration = duration
            }
        }
    }

    private func observeDuration() -> AsyncStream<TimeInterval> {
        AsyncStream { continuation in
            let cancellable = recordingService.$recordingDuration
                .sink { duration in
                    continuation.yield(duration)
                }

            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }

    private func observeTranscriptionService() {
        // Observe transcription progress
        Task {
            for await progress in observeTranscriptionProgress() {
                self.transcriptionProgress = progress
            }
        }
    }

    private func observeTranscriptionProgress() -> AsyncStream<Double> {
        AsyncStream { continuation in
            let cancellable = transcriptionService.$transcriptionProgress
                .sink { progress in
                    continuation.yield(progress)
                }

            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }

    // MARK: - Formatting Helpers

    var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
