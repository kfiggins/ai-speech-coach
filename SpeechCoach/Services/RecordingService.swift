//
//  RecordingService.swift
//  SpeechCoach
//
//  Created by AI Speech Coach
//

import Foundation
import AVFoundation

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

        // Stop recording
        recorder.stop()

        // Calculate duration
        let duration = recordingDuration

        // Update state
        await MainActor.run {
            self.isRecording = false
            self.recordingDuration = 0
        }

        // Validate recording
        try validateRecording(at: session.audioFileURL, duration: duration)

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

        if !fileManager.fileExists(atPath: url.path()) {
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
        guard fileManager.fileExists(atPath: url.path()) else {
            throw RecordingError.audioFileNotFound
        }

        // Check duration is valid
        guard duration > 0 else {
            throw RecordingError.invalidDuration
        }

        // Optionally check file size
        if let attributes = try? fileManager.attributesOfItem(atPath: url.path()),
           let fileSize = attributes[.size] as? Int64,
           fileSize == 0 {
            throw RecordingError.audioFileNotFound
        }
    }

    // MARK: - Duration Timer

    private var durationTimer: Timer?

    private func startDurationTimer() {
        durationTimer?.invalidate()

        durationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self,
                  let startTime = self.recordingStartTime else { return }

            Task { @MainActor in
                self.recordingDuration = Date().timeIntervalSince(startTime)
            }
        }
    }

    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
    }

    // MARK: - Cleanup

    deinit {
        stopDurationTimer()
    }
}

// MARK: - AVAudioRecorderDelegate

extension RecordingService: AVAudioRecorderDelegate {

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            self.isRecording = false
            self.stopDurationTimer()
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            self.isRecording = false
            self.stopDurationTimer()
        }

        if let error = error {
            print("Recording error: \(error.localizedDescription)")
        }
    }
}
