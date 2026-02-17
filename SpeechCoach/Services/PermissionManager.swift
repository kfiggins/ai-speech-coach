//
//  PermissionManager.swift
//  SpeechCoach
//
//  Created by AI Speech Coach
//

import Foundation
import AVFoundation
import Combine

/// Manages permissions for microphone access
class PermissionManager: ObservableObject {

    // MARK: - Published Properties

    @Published var microphonePermissionStatus: PermissionStatus = .notDetermined

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

    // MARK: - Combined Check

    /// Check if microphone permission is granted
    var allPermissionsGranted: Bool {
        return microphonePermissionStatus.isGranted
    }

    /// Request all required permissions
    func requestAllPermissions() async -> Bool {
        let micStatus = await requestMicrophonePermission()
        return micStatus.isGranted
    }
}
