//
//  RecordingService.swift
//  SpeechCoach
//
//  Created by AI Speech Coach
//

import Foundation
import AVFoundation
import Combine

/// Service responsible for audio recording using AVAudioRecorder
class RecordingService: NSObject, ObservableObject {

    // MARK: - Properties

    private var audioRecorder: AVAudioRecorder?
    private var currentSession: Session?
    private var recordingStartTime: Date?

    // MARK: - Recording State

    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0

    // MARK: - Errors

    enum RecordingError: LocalizedError {
        case failedToCreateDirectory
        case failedToInitializeRecorder
        case noActiveSession
        case recordingFailed(Error)
        case audioFileNotFound
        case invalidDuration

        var errorDescription: String? {
            switch self {
            case .failedToCreateDirectory:
                return "Failed to create recording directory"
            case .failedToInitializeRecorder:
                return "Failed to initialize audio recorder"
            case .noActiveSession:
                return "No active recording session"
            case .recordingFailed(let error):
                return "Recording failed: \(error.localizedDescription)"
            case .audioFileNotFound:
                return "Audio file not found after recording"
            case .invalidDuration:
                return "Recording duration is too short"
            }
        }
    }

    // MARK: - Audio Settings

    private var audioSettings: [String: Any] {
        return [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
    }

    // MARK: - Recording Control

    /// Start recording a new session
    func startRecording() async throws -> Session {
        // Create new session
        let session = Session()
        currentSession = session

        // Create session directory
        let sessionDir = SessionFileManager.sessionDirectory(for: session.id)
        try createDirectoryIfNeeded(at: sessionDir)

        // Create audio recorder
        let audioURL = session.audioFileURL
        do {
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: audioSettings)
            audioRecorder?.delegate = self
            audioRecorder?.prepareToRecord()
        } catch {
            throw RecordingError.failedToInitializeRecorder
        }

        // Start recording
        guard let recorder = audioRecorder, recorder.record() else {
            throw RecordingError.failedToInitializeRecorder
        }

        // Update state
        await MainActor.run {
            self.isRecording = true
            self.recordingStartTime = Date()
            self.recordingDuration = 0
        }

        // Start duration timer
        startDurationTimer()

        return session
    }

    /// Stop the current recording
    func stopRecording() async throws -> Session {
        guard let session = currentSession else {
            throw RecordingError.noActiveSession
        }

        guard let recorder = audioRecorder else {
            throw RecordingError.noActiveSession
        }

        // Calculate duration before stopping
        let duration = recordingDuration

        // Stop recording
        recorder.stop()

        // Stop the timer
        stopDurationTimer()

        // Wait for file to finish writing
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1.0 seconds

        // Update state
        await MainActor.run {
            self.isRecording = false
            self.recordingDuration = 0
        }

        // Debug logging
        print("Recording stopped. Expected file at: \(session.audioFileURL.path)")
        print("File exists: \(FileManager.default.fileExists(atPath: session.audioFileURL.path))")
        print("Duration: \(duration) seconds")
        if let attrs = try? FileManager.default.attributesOfItem(atPath: session.audioFileURL.path),
           let size = attrs[.size] as? Int64 {
            print("File size: \(size) bytes")
        }

        // Validate recording
        do {
            try validateRecording(at: session.audioFileURL, duration: duration)
            print("Validation passed!")
        } catch {
            print("Validation failed with error: \(error)")
            throw error
        }

        // Update session with duration
        var updatedSession = session
        updatedSession.durationSeconds = duration

        // Clean up
        audioRecorder = nil
        currentSession = nil
        recordingStartTime = nil

        return updatedSession
    }

    // MARK: - File Management

    private func createDirectoryIfNeeded(at url: URL) throws {
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.createDirectory(
                    at: url,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                throw RecordingError.failedToCreateDirectory
            }
        }
    }

    private func validateRecording(at url: URL, duration: TimeInterval) throws {
        let fileManager = FileManager.default

        // Check file exists
        guard fileManager.fileExists(atPath: url.path) else {
            throw RecordingError.audioFileNotFound
        }

        // Check duration is valid
        guard duration > 0 else {
            throw RecordingError.invalidDuration
        }

        // Optionally check file size
        if let attributes = try? fileManager.attributesOfItem(atPath: url.path),
           let fileSize = attributes[.size] as? Int64,
           fileSize == 0 {
            throw RecordingError.audioFileNotFound
        }
    }

    // MARK: - Duration Timer

    private var durationTask: Task<Void, Never>?

    private func startDurationTimer() {
        durationTask?.cancel()

        durationTask = Task { @MainActor in
            while !Task.isCancelled, let startTime = recordingStartTime {
                self.recordingDuration = Date().timeIntervalSince(startTime)
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
        }
    }

    private func stopDurationTimer() {
        durationTask?.cancel()
        durationTask = nil
    }

    // MARK: - Cleanup

    deinit {
        durationTask?.cancel()
    }
}

// MARK: - AVAudioRecorderDelegate

extension RecordingService: AVAudioRecorderDelegate {

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        stopDurationTimer()
        Task { @MainActor in
            self.isRecording = false
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        stopDurationTimer()
        Task { @MainActor in
            self.isRecording = false
        }

        if let error = error {
            print("Recording error: \(error.localizedDescription)")
        }
    }
}
