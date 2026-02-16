//
//  PermissionManager.swift
//  SpeechCoach
//
//  Created by AI Speech Coach
//

import Foundation
import AVFoundation
import Speech

/// Manages permissions for microphone and speech recognition
class PermissionManager: ObservableObject {

    // MARK: - Published Properties

    @Published var microphonePermissionStatus: PermissionStatus = .notDetermined
    @Published var speechRecognitionPermissionStatus: PermissionStatus = .notDetermined

    // MARK: - Permission Status

    enum PermissionStatus {
        case notDetermined
        case granted
        case denied
        case restricted

        var isGranted: Bool {
            return self == .granted
        }
    }

    // MARK: - Initialization

    init() {
        updateMicrophonePermissionStatus()
        updateSpeechRecognitionPermissionStatus()
    }

    // MARK: - Microphone Permissions

    /// Request microphone permission
    func requestMicrophonePermission() async -> PermissionStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)

        switch status {
        case .authorized:
            await MainActor.run {
                self.microphonePermissionStatus = .granted
            }
            return .granted

        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            let newStatus: PermissionStatus = granted ? .granted : .denied
            await MainActor.run {
                self.microphonePermissionStatus = newStatus
            }
            return newStatus

        case .denied:
            await MainActor.run {
                self.microphonePermissionStatus = .denied
            }
            return .denied

        case .restricted:
            await MainActor.run {
                self.microphonePermissionStatus = .restricted
            }
            return .restricted

        @unknown default:
            await MainActor.run {
                self.microphonePermissionStatus = .denied
            }
            return .denied
        }
    }

    /// Update current microphone permission status
    private func updateMicrophonePermissionStatus() {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)

        switch status {
        case .authorized:
            microphonePermissionStatus = .granted
        case .notDetermined:
            microphonePermissionStatus = .notDetermined
        case .denied:
            microphonePermissionStatus = .denied
        case .restricted:
            microphonePermissionStatus = .restricted
        @unknown default:
            microphonePermissionStatus = .denied
        }
    }

    // MARK: - Speech Recognition Permissions

    /// Request speech recognition permission
    func requestSpeechRecognitionPermission() async -> PermissionStatus {
        let status = SFSpeechRecognizer.authorizationStatus()

        switch status {
        case .authorized:
            await MainActor.run {
                self.speechRecognitionPermissionStatus = .granted
            }
            return .granted

        case .notDetermined:
            return await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { authStatus in
                    let newStatus: PermissionStatus
                    switch authStatus {
                    case .authorized:
                        newStatus = .granted
                    case .denied:
                        newStatus = .denied
                    case .restricted:
                        newStatus = .restricted
                    case .notDetermined:
                        newStatus = .notDetermined
                    @unknown default:
                        newStatus = .denied
                    }

                    Task { @MainActor in
                        self.speechRecognitionPermissionStatus = newStatus
                    }
                    continuation.resume(returning: newStatus)
                }
            }

        case .denied:
            await MainActor.run {
                self.speechRecognitionPermissionStatus = .denied
            }
            return .denied

        case .restricted:
            await MainActor.run {
                self.speechRecognitionPermissionStatus = .restricted
            }
            return .restricted

        @unknown default:
            await MainActor.run {
                self.speechRecognitionPermissionStatus = .denied
            }
            return .denied
        }
    }

    /// Update current speech recognition permission status
    private func updateSpeechRecognitionPermissionStatus() {
        let status = SFSpeechRecognizer.authorizationStatus()

        switch status {
        case .authorized:
            speechRecognitionPermissionStatus = .granted
        case .notDetermined:
            speechRecognitionPermissionStatus = .notDetermined
        case .denied:
            speechRecognitionPermissionStatus = .denied
        case .restricted:
            speechRecognitionPermissionStatus = .restricted
        @unknown default:
            speechRecognitionPermissionStatus = .denied
        }
    }

    // MARK: - Combined Check

    /// Check if both microphone and speech recognition permissions are granted
    var allPermissionsGranted: Bool {
        return microphonePermissionStatus.isGranted && speechRecognitionPermissionStatus.isGranted
    }

    /// Request all required permissions
    func requestAllPermissions() async -> Bool {
        let micStatus = await requestMicrophonePermission()
        let speechStatus = await requestSpeechRecognitionPermission()

        return micStatus.isGranted && speechStatus.isGranted
    }
}
