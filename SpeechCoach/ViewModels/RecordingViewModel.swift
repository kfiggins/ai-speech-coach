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
    @Published var errorMessage: String?
    @Published var showingPermissionAlert = false
    @Published var permissionAlertMessage = ""

    // MARK: - Services

    private let permissionManager: PermissionManager
    private let recordingService: RecordingService
    private let sessionStore: SessionStore

    // MARK: - Initialization

    init(
        permissionManager: PermissionManager = PermissionManager(),
        recordingService: RecordingService = RecordingService(),
        sessionStore: SessionStore = SessionStore()
    ) {
        self.permissionManager = permissionManager
        self.recordingService = recordingService
        self.sessionStore = sessionStore

        observeRecordingService()
    }

    // MARK: - Recording Control

    /// Start a new recording session
    func startRecording() {
        Task {
            do {
                // Request microphone permission
                let micStatus = await permissionManager.requestMicrophonePermission()

                guard micStatus.isGranted else {
                    showPermissionDeniedAlert()
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

    /// Stop the current recording and save audio-only session
    func stopRecording() {
        Task {
            do {
                // Stop recording and get final session
                let session = try await recordingService.stopRecording()

                currentSession = session

                // Save session to storage (audio only, no transcript yet)
                do {
                    try sessionStore.addSession(session)
                    print("Session saved successfully: \(session.id)")
                } catch {
                    print("Failed to save session: \(error.localizedDescription)")
                    errorMessage = "Session saved locally but failed to persist: \(error.localizedDescription)"
                }

                // Move to ready state immediately
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

    private func showPermissionDeniedAlert() {
        permissionAlertMessage = """
            Speech Coach needs microphone access to record your sessions.

            Please allow access in System Settings > Privacy & Security > Microphone.
            """
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

    // MARK: - Formatting Helpers

    var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
